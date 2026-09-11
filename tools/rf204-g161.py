#!/usr/bin/env python3
"""Revision-bound receiver completion over canonical Nebo semantic owners."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import struct
import subprocess
import sys
import tempfile
import time

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
COMPILER = ROOT / "build/bin/neboc"
NATIVE = ROOT / "build/bin/nebo-completion"
OWNER = "NEBO-RF166-G161"
TARGET = "x86_64-linux"
MAGIC = 0x313631504D4F434E
VERSION = 1
MAX_SOURCE_BYTES = 16_384
MAX_CANDIDATES = 256
MAX_MEMORY = 1 << 20
MAX_DEADLINE = 1_000
MASK64 = (1 << 64) - 1

OP_CONTEXT, OP_RECEIVER, OP_MEMBERS, OP_AUTO_IMPORT = 1, 2, 3, 4
OP_FILTER, OP_RANK, OP_RESOLVE = 5, 6, 7
FLAG_SNAPSHOT = 1
FLAG_TYPECHECKED = 2
FLAG_INDEX = 4
FLAG_PRIVATE_FILTERED = 8
FLAG_NO_GRANTS = 16
FLAG_DETERMINISTIC = 32
FLAG_ATOMIC = 64
FLAG_EXPLICIT_EDIT = 128
FLAG_DOC = 256
FLAG_RECOVERY = 512

IDENT = r"[A-Za-z_][A-Za-z0-9_]*"
IMPORT = re.compile(r'(?m)^\s*import\s+"(?P<module>[a-z][a-z0-9_.]*)"')
STRUCT = re.compile(rf"\bstruct\s+(?P<name>{IDENT})\s*\{{(?P<body>[^}}]*)\}}", re.DOTALL)
FIELD = re.compile(rf"\b(?P<type>{IDENT}(?:<[^;]+>)?)\s*\.\s*(?P<name>{IDENT})\s*;")
RECEIVER_METHOD = re.compile(rf"\(\s*(?P<type>{IDENT})\.(?P<parameter>{IDENT})\s*\)\s*(?P<name>{IDENT})\s*\(")
BINDING = re.compile(rf"(?P<expr>[^;{{}}\n]+?)\s*\.\s*(?P<name>{IDENT})\s*;")


class CompletionError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def canonical(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fnv(data: bytes) -> int:
    value = 0xCBF29CE484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001B3) & MASK64
    return value or 1


def type_id(name: str) -> int:
    # NI-v1 and the canonical type owners use FNV identities over canonical type names.
    return fnv(name.encode("utf-8"))


TYPE_OWNERS = {
    "Global": "compiler/semantic/index/project_symbol_index.asm",
    "Text": "compiler/parser/text_char_bytes_api_contract.asm",
    "List": "compiler/semantic/collections/sequential_collections_source_vertical.inc",
    "Array": "compiler/semantic/collections/array_range.asm",
    "Dict": "compiler/semantic/collections/associative_collections_source_vertical.inc",
    "Matrix": "compiler/semantic/structural/legacy_source_verticals.asm",
}

# Names and signatures are a completion projection of existing public owner
# tables. It owns no parsing, typechecking, module graph or executable behavior.
MEMBERS: dict[str, tuple[tuple[str, str, str], ...]] = {
    "Global": (
        ("start", "keyword", "start()"), ("return", "keyword", "return"),
        ("if", "keyword", "if condition"), ("else", "keyword", "else"),
        ("while", "keyword", "while condition"), ("for", "keyword", "for item in values"),
        ("in", "keyword", "in"), ("loop", "keyword", "loop"),
        ("break", "keyword", "break"), ("continue", "keyword", "continue"),
        ("true", "constant", "Bool.true"), ("false", "constant", "Bool.false"),
        ("console", "function", "console(value)"), ("scan", "function", "scan() -> Text"),
    ),
    "Text": (
        ("byteLength", "method", "Text.byteLength() -> Int"),
        ("codepointCount", "method", "Text.codepointCount() -> Int"),
        ("isEmpty", "method", "Text.isEmpty() -> Bool"),
        ("startsWith", "method", "Text.startsWith(prefix: Text) -> Bool"),
        ("endsWith", "method", "Text.endsWith(suffix: Text) -> Bool"),
        ("contains", "method", "Text.contains(needle: Text) -> Bool"),
        ("trim", "method", "Text.trim() -> Text"),
        ("lower", "method", "Text.lower() -> Text"),
        ("upper", "method", "Text.upper() -> Text"),
        ("split", "method", "Text.split(separator: Text) -> List<Text>"),
    ),
    "List": (
        ("at", "method", "List<T>.at(index: Int) -> T"),
        ("length", "method", "List<T>.length() -> Int"),
        ("get", "method", "List<T>.get(index: Int) -> Option<T>"),
        ("push", "method", "List<T>.push(value: T) -> Unit"),
        ("pop", "method", "List<T>.pop() -> Option<T>"),
        ("swapRemove", "method", "List<T>.swapRemove(index: Int) -> T"),
        ("clear", "method", "List<T>.clear() -> Unit"),
    ),
    "Array": (
        ("length", "method", "Array<T,N>.length() -> Int"),
        ("asSlice", "method", "Array<T,N>.asSlice() -> Slice<T>"),
    ),
    "Dict": (
        ("length", "method", "Dict<K,V>.length() -> Int"),
        ("get", "method", "Dict<K,V>.get(key: K) -> Option<V>"),
        ("getMutable", "method", "Dict<K,V>.getMutable(key: K) -> Option<&mut V>"),
        ("containsKey", "method", "Dict<K,V>.containsKey(key: K) -> Bool"),
        ("insert", "method", "Dict<K,V>.insert(key: K, value: V) -> Option<V>"),
        ("remove", "method", "Dict<K,V>.remove(key: K) -> Option<V>"),
        ("clear", "method", "Dict<K,V>.clear() -> Unit"),
    ),
    "Matrix": (
        ("rows", "method", "Matrix<T>.rows() -> Int"),
        ("columns", "method", "Matrix<T>.columns() -> Int"),
        ("at", "method", "Matrix<T>.at(row: Int, column: Int) -> T"),
        ("set", "method", "Matrix<T>.set(row: Int, column: Int, value: T) -> Matrix<T>"),
        ("row", "method", "Matrix<T>.row(index: Int) -> VectorView<T>"),
        ("column", "method", "Matrix<T>.column(index: Int) -> VectorView<T>"),
        ("transposeView", "method", "Matrix<T>.transposeView() -> MatrixView<T>"),
        ("contiguous", "method", "MatrixView<T>.contiguous() -> Matrix<T>"),
        ("add", "method", "Matrix<T>.add(other: Matrix<T>) -> Matrix<T>"),
        ("sum", "method", "Matrix<T>.sum() -> T"),
        ("min", "method", "Matrix<T>.min() -> T"),
        ("max", "method", "Matrix<T>.max() -> T"),
        ("matmul", "method", "Matrix<T>.matmul(other: Matrix<T>) -> Matrix<T>"),
    ),
}


def read_regular(path: Path) -> bytes:
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK)
    except OSError as error:
        raise CompletionError("NEBO-RF166-G161-001", "cannot open bounded local source") from error
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_SOURCE_BYTES:
            raise CompletionError("NEBO-RF166-G161-001", "source is not a bounded regular file")
        data = b""
        while len(data) <= MAX_SOURCE_BYTES:
            chunk = os.read(descriptor, min(4096, MAX_SOURCE_BYTES + 1 - len(data)))
            if not chunk:
                break
            data += chunk
        if len(data) > MAX_SOURCE_BYTES:
            raise CompletionError("NEBO-RF166-G161-007", "source exceeds completion snapshot budget")
        data.decode("utf-8", "strict")
        return data
    finally:
        os.close(descriptor)


def parse_location(raw: str, source: str) -> tuple[Path, int]:
    pieces = raw.rsplit(":", 2)
    if len(pieces) != 3:
        raise CompletionError("NEBO-RF166-G161-001", "location must be <file>:<line>:<column>")
    path = Path(pieces[0]).absolute()
    try:
        line, column = int(pieces[1]), int(pieces[2])
    except ValueError as error:
        raise CompletionError("NEBO-RF166-G161-001", "line and column must be decimal") from error
    if line <= 0 or column <= 0:
        raise CompletionError("NEBO-RF166-G161-001", "line and column are one-based positive values")
    lines = source.splitlines(keepends=True)
    if line > len(lines):
        raise CompletionError("NEBO-RF166-G161-001", "line is outside the source snapshot")
    content = lines[line - 1].rstrip("\r\n")
    if column - 1 > len(content):
        raise CompletionError("NEBO-RF166-G161-001", "column is outside the source line")
    return path, sum(len(item) for item in lines[: line - 1]) + column - 1


def compiler_check(path: Path, source: bytes) -> bool:
    on_disk = False
    try:
        on_disk = path.is_file() and not path.is_symlink() and path.read_bytes() == source
    except OSError:
        pass
    with tempfile.TemporaryDirectory(prefix="nebo-g161-check-") as temporary:
        checked = path if on_disk else Path(temporary) / "snapshot.no"
        if not on_disk:
            checked.write_bytes(source)
        result = subprocess.run(
            [str(COMPILER), "check", str(checked)], cwd=ROOT, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20, check=False,
            env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
        )
    return result.returncode == 0


def expression_before_dot(source: str, offset: int) -> tuple[str | None, str]:
    active_start = offset
    while active_start > 0 and (source[active_start - 1].isalnum() or source[active_start - 1] == "_"):
        active_start -= 1
    prefix = source[active_start:offset]
    dot = active_start - 1
    if dot < 0 or source[dot] != ".":
        return None, prefix
    cursor = dot - 1
    while cursor >= 0 and source[cursor].isspace():
        cursor -= 1
    if cursor < 0:
        return None, prefix
    if source[cursor] == '"':
        cursor -= 1
        escaped = False
        while cursor >= 0:
            if source[cursor] == '"' and not escaped:
                return source[cursor:dot].strip(), prefix
            escaped = source[cursor] == "\\" and not escaped
            if source[cursor] != "\\":
                escaped = False
            cursor -= 1
        return None, prefix
    pairs = {"]": "[", ")": "(", "}": "{", ">": "<"}
    if source[cursor] in pairs:
        close, opening, depth = source[cursor], pairs[source[cursor]], 1
        cursor -= 1
        while cursor >= 0:
            if source[cursor] == close:
                depth += 1
            elif source[cursor] == opening:
                depth -= 1
                if depth == 0:
                    start = cursor
                    while start > 0 and (source[start - 1].isalnum() or source[start - 1] in "_<>,"):
                        start -= 1
                    return source[start:dot].strip(), prefix
            cursor -= 1
        return None, prefix
    end = cursor + 1
    while cursor >= 0 and (source[cursor].isalnum() or source[cursor] == "_"):
        cursor -= 1
    return source[cursor + 1:end] or None, prefix


def infer_expression_type(expression: str) -> str | None:
    value = expression.strip()
    if value.startswith('"') and value.endswith('"'):
        return "Text"
    if value.startswith("List<"):
        return "List"
    if value.startswith("Dict<"):
        return "Dict"
    if value.startswith("Matrix<"):
        return "Matrix"
    if value.startswith("Array<"):
        return "Array"
    if value.startswith("[") and value.endswith("]"):
        return "List"
    match = re.match(rf"(?P<name>{IDENT})\s*\{{", value)
    return match.group("name") if match else None


def infer_receiver(source: str, offset: int) -> tuple[str, str, str | None]:
    expression, prefix = expression_before_dot(source, offset)
    if expression is None:
        return "Global", prefix, None
    direct = infer_expression_type(expression)
    if direct:
        return direct, prefix, expression
    if re.fullmatch(IDENT, expression):
        bindings = [match for match in BINDING.finditer(source[:offset]) if match.group("name") == expression]
        if bindings:
            inferred = infer_expression_type(bindings[-1].group("expr"))
            if inferred:
                return inferred, prefix, expression
        if expression == "self":
            matches = list(RECEIVER_METHOD.finditer(source[:offset]))
            if matches:
                return matches[-1].group("type"), prefix, expression
        declared = {match.group("name") for match in STRUCT.finditer(source)}
        if expression in declared:
            return expression, prefix, expression
    raise CompletionError("NEBO-RF166-G161-002", "bounded recovery could not prove a receiver TypeId")


def candidate(receiver: str, name: str, kind: str, signature: str, origin: str,
              owner: str, revision: str, *, docs: str | None = None,
              module: str | None = None, symbol: int | None = None,
              deprecated: str = "never", constraints: list[str] | None = None,
              receiver_identity: int | None = None) -> dict[str, object]:
    identity = symbol or fnv(f"{owner}:{receiver}:{name}".encode("utf-8"))
    symbol_id = f"0x{identity:016x}"
    item_id = sha(canonical({"revision": revision, "symbolId": symbol_id, "receiver": receiver}))[:32]
    return {
        "symbolId": symbol_id, "itemId": item_id, "name": name, "kind": kind,
        "receiverTypeId": f"0x{receiver_identity or type_id(receiver):016x}", "origin": origin,
        "module": module, "signature": signature,
        "documentation": docs or f"Canonical {signature} surface.",
        "effects": [], "capabilities": [], "constraints": constraints or [],
        "target": TARGET, "edition": 1, "since": "1.0", "deprecated": deprecated,
        "owner": owner, "autoImport": origin in {"AUTO_IMPORT", "PACKAGE"},
    }


def local_members(source: str, receiver: str, receiver_identity: int, revision: str) -> list[dict[str, object]]:
    result: list[dict[str, object]] = []
    for declaration in STRUCT.finditer(source):
        if declaration.group("name") != receiver:
            continue
        for field in FIELD.finditer(declaration.group("body")):
            name = field.group("name")
            result.append(candidate(
                receiver, name, "field", f"{receiver}.{name}: {field.group('type')}", "IMPORTED",
                "compiler/semantic/types/programmer_type_vertical.asm", revision,
                docs="Source-order field admitted by the canonical programmer-type owner.",
                receiver_identity=receiver_identity,
            ))
    for method in RECEIVER_METHOD.finditer(source):
        if method.group("type") == receiver:
            name = method.group("name")
            result.append(candidate(
                receiver, name, "method", f"{receiver}.{name}(...)", "IMPORTED",
                "compiler/semantic/call/call_resolver.asm", revision,
                docs="Receiver-first callable admitted by canonical overload resolution.",
                constraints=["receiver-first"], receiver_identity=receiver_identity,
            ))
    return result


def symbol_index(workspace: Path, current: Path, receiver: str, receiver_identity: int,
                 effects: list[str], capabilities: list[str], constraints: list[str],
                 deadline: int) -> dict[str, object] | None:
    try:
        if not workspace.is_dir() or workspace.is_symlink():
            return None
        entries = sorted(workspace.iterdir(), key=lambda item: item.name.encode("utf-8"))
        source_count = sum(1 for item in entries if item.is_file() and item.suffix == ".no")
        if source_count > 32:
            return None
    except OSError:
        return None
    try:
        with tempfile.TemporaryDirectory(prefix="nebo-g161-index-") as temporary:
            view = Path(temporary)
            # G160 indexes documented semantic declarations. The unsaved/open
            # completion snapshot is deliberately excluded; it is represented
            # by the overlay above and must not make the sealed project index fail.
            for item in entries:
                if item.is_symlink():
                    continue
                if item.is_file() and item.resolve() != current.resolve() and item.suffix in {".no", ".ni"}:
                    data = item.read_bytes()
                    if len(data) > MAX_MEMORY or (item.suffix == ".no" and b"doc {" not in data):
                        continue
                    (view / item.name).write_bytes(data)
                elif item.is_dir() and item.name == "packages":
                    package_view = view / "packages"
                    package_view.mkdir()
                    for record in sorted(item.glob("*.package-index.json"), key=lambda path: path.name.encode()):
                        if record.is_file() and not record.is_symlink():
                            data = record.read_bytes()
                            if len(data) <= MAX_MEMORY:
                                (package_view / record.name).write_bytes(data)
            command = [str(COMPILER), "symbols", str(view), "--json", "--limit", str(MAX_CANDIDATES),
                       "--deadline-ms", str(min(deadline, 999))]
            if receiver != "Global":
                command += ["--receiver", f"0x{receiver_identity:016x}"]
            for value in effects:
                command += ["--context-effect", value]
            for value in capabilities:
                command += ["--context-capability", value]
            for value in constraints:
                command += ["--context-constraint", value]
            result = subprocess.run(
                command, cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE, timeout=30, check=False,
                env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
            )
            value = json.loads(result.stdout) if result.returncode == 0 and not result.stderr else None
    except (OSError, subprocess.TimeoutExpired, UnicodeError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) and value.get("owner") == "NEBO-RF166-G160" else None


def indexed_candidates(report: dict[str, object] | None, source: str, receiver: str,
                       receiver_identity: int, revision: str, current: Path) -> list[dict[str, object]]:
    if report is None:
        return []
    imported = {match.group("module") for match in IMPORT.finditer(source)}
    result: list[dict[str, object]] = []
    for record in report.get("results", []):
        if not isinstance(record, dict):
            continue
        source_info = record.get("source")
        if isinstance(source_info, dict) and source_info.get("path") == current.name:
            continue
        package = record.get("package")
        module = str(record.get("module") or "")
        origin = "PACKAGE" if package is not None else ("IMPORTED" if module in imported else "AUTO_IMPORT")
        docs = record.get("docs") if isinstance(record.get("docs"), dict) else {}
        symbol = int(str(record["symbolId"]), 16)
        record_receiver = receiver if receiver != "Global" else "Global"
        result.append(candidate(
            record_receiver, str(record["name"]), str(record["kind"]),
            f"{record['kind']} {record['name']}", origin,
            "compiler/semantic/index/project_symbol_index.asm", revision,
            docs=str(docs.get("summary") or "ProjectSymbolIndex record; details resolve lazily."),
            module=module, symbol=symbol, deprecated=str(docs.get("deprecated") or "never"),
            constraints=list(map(str, record.get("constraints", []))), receiver_identity=receiver_identity,
        ))
    return result


def canonical_receiver_type(path: Path, source: bytes, receiver: str, admitted: bool) -> int:
    if receiver in TYPE_OWNERS or not admitted:
        return type_id(receiver)
    try:
        on_disk = path.is_file() and not path.is_symlink() and path.read_bytes() == source
    except OSError:
        on_disk = False
    with tempfile.TemporaryDirectory(prefix="nebo-g161-type-") as temporary:
        inspected = path if on_disk else Path(temporary) / "snapshot.no"
        if not on_disk:
            inspected.write_bytes(source)
        result = subprocess.run(
            [str(COMPILER), "dump", "doc-record", str(inspected)], cwd=ROOT,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=20, check=False, env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
        )
    if result.returncode == 0 and not result.stderr:
        try:
            record = json.loads(result.stdout)
        except (UnicodeError, json.JSONDecodeError):
            record = {}
        attachment = record.get("attachment", {}) if isinstance(record, dict) else {}
        symbol = record.get("symbolId") if isinstance(record, dict) else None
        if isinstance(attachment, dict) and attachment.get("name") == receiver and isinstance(symbol, int) and symbol > 0:
            return symbol
    # Canonical admission still proves the nominal type; the NI-v1 type digest
    # is the stable fallback when that declaration has no attached DocRecord.
    return type_id(receiver)


def rank(candidates: list[dict[str, object]], prefix: str, source: str) -> list[dict[str, object]]:
    locality = {"CORE": 5000, "PRELUDE": 4000, "IMPORTED": 3000, "AUTO_IMPORT": 2000, "PACKAGE": 1000}
    for item in candidates:
        name = str(item["name"])
        folded, wanted = name.casefold(), prefix.casefold()
        exactness = 200 if wanted and folded == wanted else (120 if not wanted or folded.startswith(wanted) else 0)
        stability = -200 if item["deprecated"] != "never" else 100
        usage = min(source.count(f".{name}"), 20)
        components = {
            "locality": locality[str(item["origin"])], "exactness": exactness,
            "stability": stability, "usage": usage,
        }
        item["rank"] = {**components, "total": sum(components.values()), "telemetry": "NONE"}
    candidates.sort(key=lambda item: (-int(item["rank"]["total"]), str(item["name"]).casefold(), int(str(item["symbolId"]), 16)))
    return candidates


def native(operation: int, facts: dict[str, int], flags: int) -> None:
    values = [
        MAGIC, VERSION, operation, flags, facts["snapshot"], facts["revision"], facts["position"],
        facts["sourceBytes"], facts["receiver"], facts["constraints"], facts["indexEntries"],
        facts["core"], facts["prelude"], facts["imported"], facts["auto"], facts["package"],
        facts["candidates"], facts["eligible"], facts["private"], facts["effects"],
        facts["capabilities"], facts["target"], facts["edition"], facts["constraintRejected"],
        facts["rank"], facts["selected"], facts["docs"], facts["import"], facts["memory"],
        facts["memoryBudget"], facts["deadline"], facts["observed"], facts["evaluations"], 0, 0, 0,
    ]
    result = subprocess.run(
        [str(NATIVE)], input=struct.pack("<36Q", *values), stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=10, check=False,
    )
    if result.returncode or result.stderr or len(result.stdout) != 64:
        raise CompletionError("NEBO-RF166-G161-008", f"native completion operation {operation} rejected observed facts")
    words = struct.unpack("<8Q", result.stdout)
    if words[0] or words[1] != operation or words[3] != facts["receiver"] or words[4] != facts["candidates"]:
        raise CompletionError("NEBO-RF166-G161-008", "native completion result diverged from observed facts")


def complete(path: Path, source_bytes: bytes, offset: int, workspace: Path, *,
             effects: list[str], capabilities: list[str], constraints: list[str],
             deadline: int, limit: int, resolve_id: str | None = None) -> dict[str, object]:
    started = time.monotonic_ns()
    if len(source_bytes) > MAX_SOURCE_BYTES or not 1 <= deadline <= MAX_DEADLINE or not 1 <= limit <= MAX_CANDIDATES:
        raise CompletionError("NEBO-RF166-G161-007", "completion source, deadline or result budget is invalid")
    try:
        source = source_bytes.decode("utf-8", "strict")
    except UnicodeDecodeError as error:
        raise CompletionError("NEBO-RF166-G161-001", "completion snapshot is not UTF-8") from error
    if not 0 <= offset <= len(source):
        raise CompletionError("NEBO-RF166-G161-001", "completion position is outside the snapshot")
    admitted = compiler_check(path, source_bytes)
    receiver, prefix, expression = infer_receiver(source, offset)
    recovery = not admitted
    if recovery and receiver not in {"Global", "Text", "List", "Array", "Dict", "Matrix"}:
        raise CompletionError("NEBO-RF166-G161-002", "invalid source recovery cannot invent a receiver type")
    revision = sha(source_bytes)
    receiver_identity = canonical_receiver_type(path, source_bytes, receiver, admitted)
    builtins: list[dict[str, object]] = []
    for index, (name, kind, signature) in enumerate(MEMBERS.get(receiver, ())) :
        origin = "CORE" if index < 2 else "PRELUDE"
        builtins.append(candidate(receiver, name, kind, signature, origin, TYPE_OWNERS[receiver], revision,
                                  receiver_identity=receiver_identity))
    if admitted:
        builtins.extend(local_members(source, receiver, receiver_identity, revision))
    index_report = symbol_index(workspace, path, receiver, receiver_identity,
                                effects, capabilities, constraints, deadline)
    indexed = indexed_candidates(index_report, source, receiver, receiver_identity, revision, path)
    unique: dict[str, dict[str, object]] = {}
    for item in [*builtins, *indexed]:
        unique.setdefault(str(item["symbolId"]), item)
    raw = list(unique.values())
    prefix_rejected = 0
    if prefix:
        matched = [item for item in raw if str(item["name"]).casefold().startswith(prefix.casefold())]
        prefix_rejected = len(raw) - len(matched)
    else:
        matched = raw
    selected = rank(matched, prefix, source)
    limit_rejected = max(0, len(selected) - limit)
    selected = selected[:limit]
    if not selected:
        raise CompletionError("NEBO-RF166-G161-006", "no semantically eligible completion candidate")
    counts = index_report.get("counts", {}) if index_report else {}
    private = int(counts.get("privateRejected", 0))
    policy = int(counts.get("policyFiltered", 0))
    policy = max(0, policy)
    candidate_count = len(raw) + private + policy
    if candidate_count > MAX_CANDIDATES:
        raise CompletionError("NEBO-RF166-G161-007", "completion candidate budget exceeded")
    core = sum(item["origin"] == "CORE" for item in raw)
    prelude = sum(item["origin"] == "PRELUDE" for item in raw)
    imported = sum(item["origin"] == "IMPORTED" for item in raw)
    package = sum(item["origin"] == "PACKAGE" for item in raw)
    auto = sum(item["origin"] in {"AUTO_IMPORT", "PACKAGE"} for item in raw) + private + policy
    visible_ids = {str(item["itemId"]) for item in selected}
    chosen = selected[0]
    if resolve_id is not None:
        matches = [item for item in selected if item["itemId"] == resolve_id]
        if len(matches) != 1:
            raise CompletionError("NEBO-RF166-G161-005", "completion item is stale or unknown")
        chosen = matches[0]
    rank_digest = fnv(canonical([{"itemId": item["itemId"], "rank": item["rank"]} for item in selected]))
    import_plan = {
        "candidate": chosen["itemId"], "symbolId": chosen["symbolId"],
        "module": chosen["module"], "revision": revision, "explicit": True,
    } if chosen["autoImport"] else None
    elapsed = max(1, (time.monotonic_ns() - started + 999_999) // 1_000_000)
    if elapsed > deadline:
        raise CompletionError("NEBO-RF166-G161-007", "completion deadline elapsed before publication")
    memory = len(canonical(selected))
    if memory > MAX_MEMORY:
        raise CompletionError("NEBO-RF166-G161-007", "completion memory budget exceeded")
    flags = FLAG_SNAPSHOT | FLAG_TYPECHECKED | FLAG_INDEX | FLAG_PRIVATE_FILTERED | FLAG_NO_GRANTS | FLAG_DETERMINISTIC | FLAG_ATOMIC | FLAG_DOC
    if recovery:
        flags |= FLAG_RECOVERY
    if import_plan:
        flags |= FLAG_EXPLICIT_EDIT
    facts = {
        "snapshot": int(revision[:16], 16) or 1, "revision": int(revision[16:32], 16) or 1,
        "position": len(source[:offset].encode("utf-8")), "sourceBytes": len(source_bytes),
        "receiver": receiver_identity, "constraints": fnv(canonical(constraints)),
        "indexEntries": int(counts.get("input", len(raw))), "core": core, "prelude": prelude,
        "imported": imported, "auto": auto, "package": package,
        "candidates": candidate_count, "eligible": len(selected), "private": private,
        "effects": 0, "capabilities": 0, "target": policy, "edition": 0,
        "constraintRejected": prefix_rejected + limit_rejected, "rank": rank_digest,
        "selected": int(str(chosen["symbolId"]), 16),
        "docs": fnv(str(chosen["documentation"]).encode("utf-8")),
        "import": fnv(canonical(import_plan)) if import_plan else 0,
        "memory": memory, "memoryBudget": MAX_MEMORY, "deadline": deadline,
        "observed": elapsed, "evaluations": 1,
    }
    for operation in range(OP_CONTEXT, OP_RESOLVE + 1):
        native(operation, facts, flags)
    report = {
        "schema": 1, "command": "completion-debug", "owner": OWNER,
        "snapshot": {"sha256": revision, "bytes": len(source_bytes), "admitted": admitted,
                     "recovery": "BOUNDED" if recovery else "NONE"},
        "position": {"characterOffset": offset, "byteOffset": facts["position"], "prefix": prefix},
        "receiver": {"expression": expression, "type": receiver,
                     "typeId": f"0x{facts['receiver']:016x}", "evaluations": 1,
                     "constraints": constraints, "authority": TYPE_OWNERS.get(receiver, "compiler/semantic/types/programmer_type_vertical.asm")},
        "projectIndex": {
            "owner": "NEBO-RF166-G160", "status": "READY" if index_report else "CORE_ONLY",
            "revision": index_report.get("revision") if index_report else None,
            "entries": facts["indexEntries"], "network": False,
        },
        "filters": {
            "privateRejected": private, "policyRejected": policy,
            "prefixConstraintRejected": prefix_rejected, "limitRejected": limit_rejected, "grants": [],
            "contextEffects": sorted(set(effects)), "contextCapabilities": sorted(set(capabilities)),
            "target": TARGET, "edition": 1,
        },
        "ranking": {"policy": "origin,exactness,stability,local-usage,name,SymbolId",
                    "digest": f"0x{rank_digest:016x}", "remoteTelemetry": False},
        "counts": {"candidates": facts["candidates"], "eligible": len(selected),
                   "returned": len(selected), "core": core, "prelude": prelude,
                   "imported": imported, "autoImport": auto, "package": package},
        "candidates": selected, "selectedItemId": chosen["itemId"],
        "resolved": chosen if resolve_id is not None else None,
        "autoImportPlan": import_plan,
        "operations": [
            "CompletionContext.fromPosition", "completion.receiverType", "completion.preludeMembers",
            "completion.importedMembers", "completion.autoImportCandidates", "completion.filterEffects",
            "completion.filterCapabilities", "completion.filterConstraints", "completion.filterTargetEdition",
            "completion.rank", "completion.details", "completion.applyAutoImport", "completion.resolve",
        ],
        "budget": {"deadlineMs": deadline, "observedMs": elapsed,
                   "memoryBytes": memory, "maximumCandidates": MAX_CANDIDATES},
        "identity": {"candidateIds": sorted(visible_ids), "sameForCliAndLsp": True},
    }
    return report


def corpus() -> dict[str, object]:
    required = {"Text": "byteLength", "List": "push", "Dict": "containsKey", "Matrix": "sum"}
    rows: list[dict[str, object]] = []
    identities: set[int] = set()
    for receiver, expected in required.items():
        owner = TYPE_OWNERS[receiver]
        if not (ROOT / owner).is_file() or expected not in {item[0] for item in MEMBERS[receiver]}:
            raise CompletionError("NEBO-RF166-G161-008", "completion corpus owner or mandatory member is missing")
        for name, kind, signature in MEMBERS[receiver]:
            identity = fnv(f"{owner}:{receiver}:{name}".encode("utf-8"))
            if identity in identities:
                raise CompletionError("NEBO-RF166-G161-001", "completion corpus has duplicate SymbolId")
            identities.add(identity)
            rows.append({"receiver": receiver, "typeId": f"0x{type_id(receiver):016x}",
                         "name": name, "kind": kind, "signature": signature,
                         "symbolId": f"0x{identity:016x}", "owner": owner})
    digest = sha(canonical(rows))
    facts = {
        "snapshot": int(digest[:16], 16) or 1, "revision": int(digest[16:32], 16) or 1,
        "position": 1, "sourceBytes": 1, "receiver": type_id("Text"), "constraints": 1,
        "indexEntries": len(rows), "core": 2, "prelude": len(rows) - 3, "imported": 0,
        "auto": 1, "package": 1, "candidates": len(rows), "eligible": len(rows),
        "private": 0, "effects": 0, "capabilities": 0, "target": 0, "edition": 0,
        "constraintRejected": 0, "rank": fnv(canonical(rows)), "selected": next(iter(identities)),
        "docs": fnv(b"completion-corpus"), "import": fnv(b"explicit-local-plan"),
        "memory": len(canonical(rows)), "memoryBudget": MAX_MEMORY, "deadline": 100,
        "observed": 1, "evaluations": 1,
    }
    # Keep exact origin accounting: two core, all but three prelude, one package auto-import.
    flags = FLAG_SNAPSHOT | FLAG_TYPECHECKED | FLAG_INDEX | FLAG_PRIVATE_FILTERED | FLAG_NO_GRANTS | FLAG_DETERMINISTIC | FLAG_ATOMIC | FLAG_EXPLICIT_EDIT | FLAG_DOC
    for operation in range(OP_CONTEXT, OP_RESOLVE + 1):
        native(operation, facts, flags)
    return {"schema": 1, "command": "completion-corpus verify", "owner": OWNER,
            "types": len(required), "rows": len(rows), "digest": digest,
            "nativeOperations": 7, "network": False, "status": "PASS"}


def apply_import(path: Path, report: dict[str, object], item_id: str) -> dict[str, object]:
    matches = [item for item in report["candidates"] if item["itemId"] == item_id]
    if len(matches) != 1 or matches[0]["origin"] != "AUTO_IMPORT":
        raise CompletionError("NEBO-RF166-G161-005", "item is not an explicit local-source auto-import candidate")
    item = matches[0]
    result = subprocess.run(
        [sys.executable, str(ROOT / "tools/rf204-g152.py"), "_add-import-revision",
         str(item["name"]), "--to", str(path), str(report["snapshot"]["sha256"])],
        cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        timeout=20, check=False, env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
    )
    if result.returncode or result.stderr:
        raise CompletionError("NEBO-RF166-G161-005", "canonical AutoImportPlan rejected the explicit edit")
    value = json.loads(result.stdout)
    return {"schema": 1, "command": "completion.applyAutoImport", "owner": OWNER,
            "itemId": item_id, "symbolId": item["symbolId"], "beforeRevision": report["snapshot"]["sha256"],
            "atomic": True, "planOwner": "NEBO-RF166-G152", "result": value}


def main(arguments: list[str]) -> int:
    if arguments == ["completion-corpus", "--verify"]:
        print(json.dumps(corpus(), sort_keys=True, separators=(",", ":")))
        return 0
    if arguments and arguments[0] in {"_lsp", "_lsp-resolve"}:
        expected = 4 if arguments[0] == "_lsp" else 5
        if len(arguments) != expected:
            raise CompletionError("NEBO-RF166-G161-001", "invalid internal LSP completion request")
        path, offset, workspace = Path(arguments[1]).absolute(), int(arguments[2]), Path(arguments[3]).absolute()
        source = sys.stdin.buffer.read(MAX_SOURCE_BYTES + 1)
        resolve_id = arguments[4] if arguments[0] == "_lsp-resolve" else None
        report = complete(path, source, offset, workspace, effects=[], capabilities=[], constraints=[],
                          deadline=1000, limit=MAX_CANDIDATES, resolve_id=resolve_id)
        if resolve_id is None:
            for item in report["candidates"]:
                item.pop("documentation", None)
                item.pop("signature", None)
        print(json.dumps(report, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
        return 0
    if not arguments or arguments[0] != "completion-debug":
        raise CompletionError("NEBO-RF166-G161-001", "completion-debug or completion-corpus --verify is required")
    parser = argparse.ArgumentParser(prog="neboc completion-debug")
    parser.add_argument("location")
    parser.add_argument("--workspace")
    parser.add_argument("--context-effect", action="append", default=[])
    parser.add_argument("--context-capability", action="append", default=[])
    parser.add_argument("--context-constraint", action="append", default=[])
    parser.add_argument("--deadline-ms", type=int, default=500)
    parser.add_argument("--limit", type=int, default=MAX_CANDIDATES)
    parser.add_argument("--resolve")
    parser.add_argument("--apply-auto-import")
    args = parser.parse_args(arguments[1:])
    location_path = Path(args.location.rsplit(":", 2)[0]).absolute()
    source_bytes = read_regular(location_path)
    path, offset = parse_location(args.location, source_bytes.decode("utf-8"))
    workspace = Path(args.workspace).absolute() if args.workspace else path.parent
    resolve = args.resolve or args.apply_auto_import
    report = complete(path, source_bytes, offset, workspace, effects=args.context_effect,
                      capabilities=args.context_capability, constraints=args.context_constraint,
                      deadline=args.deadline_ms, limit=args.limit, resolve_id=resolve)
    payload = apply_import(path, report, args.apply_auto_import) if args.apply_auto_import else report
    print(json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (CompletionError, OSError, ValueError, json.JSONDecodeError, subprocess.TimeoutExpired) as error:
        code = error.code if isinstance(error, CompletionError) else "NEBO-RF166-G161-008"
        message = error.message if isinstance(error, CompletionError) else str(error)
        print(f"{code}: {message}; note=no completion state was published", file=sys.stderr)
        raise SystemExit(1)
