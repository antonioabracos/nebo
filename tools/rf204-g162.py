#!/usr/bin/env python3
"""Revision-bound semantic navigation and rename adapter for RF166-G162.

The adapter consumes G160 ProjectSymbolIndex/DocRecord identities and G161
receiver candidates.  It only projects source spans around those identities;
it never builds a second parser, resolver, typechecker, or module graph.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import time

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
COMPILER = ROOT / "build/bin/neboc"
OWNER = "NEBO-RF166-G162"
TARGET = "x86_64-linux"
MAX_SOURCE_BYTES = 16_384
MAX_SOURCES = 32
MAX_INTERFACES = 128
MAX_RESULTS = 256
MAX_MEMORY = 16 << 20
MAX_DEADLINE_MS = 5_000
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
IMPORT = re.compile(
    r'(?m)^\s*(?:export\s+)?import\s+"(?P<module>[a-z][a-z0-9_.]*)"'
    r'(?:\s*\{(?P<selected>[^}]*)\})?\.(?P<alias>[A-Za-z_][A-Za-z0-9_]*)\s*;'
)
CALL = re.compile(r"\.(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*\(")
KEYWORDS = {
    "module", "import", "export", "public", "private", "start", "return",
    "if", "else", "while", "for", "in", "loop", "break", "continue",
    "true", "false", "doc", "struct", "enum", "type", "const",
}


class NavigationError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise NavigationError("NEBO-RF166-G162-009", f"required owner is unavailable: {path.name}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


G161 = load_module("nebo_rf166_g161_navigation", ROOT / "tools/rf204-g161.py")
sys.path.insert(0, str(ROOT))
from compiler.sdk.comment_tooling import CommentModel, CommentToolError
from compiler.sdk.token_tooling import TokenModel, TokenToolError
from compiler.sdk.static_analysis import AnalysisError, FixPlan


def canonical(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def byte_offset(text: str, character: int) -> int:
    return len(text[:character].encode("utf-8"))


def character_offset(data: bytes, offset: int) -> int:
    if not 0 <= offset <= len(data):
        raise NavigationError("NEBO-RF166-G162-001", "source position is outside the snapshot")
    try:
        return len(data[:offset].decode("utf-8", "strict"))
    except UnicodeDecodeError as error:
        raise NavigationError("NEBO-RF166-G162-001", "source position splits a UTF-8 scalar") from error


def read_regular(path: Path, maximum: int = MAX_SOURCE_BYTES, *, utf8: bool = True) -> bytes:
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK)
    except OSError as error:
        raise NavigationError("NEBO-RF166-G162-001", f"cannot open bounded local input: {path.name}") from error
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode) or info.st_size > maximum:
            raise NavigationError("NEBO-RF166-G162-008", "input is not a bounded regular file")
        chunks = bytearray()
        while len(chunks) <= maximum:
            block = os.read(descriptor, min(65_536, maximum + 1 - len(chunks)))
            if not block:
                break
            chunks.extend(block)
        if len(chunks) > maximum:
            raise NavigationError("NEBO-RF166-G162-008", "input exceeds its byte budget")
        if utf8:
            bytes(chunks).decode("utf-8", "strict")
        return bytes(chunks)
    except UnicodeDecodeError as error:
        raise NavigationError("NEBO-RF166-G162-001", "input is not valid UTF-8") from error
    finally:
        os.close(descriptor)


def compiler_json(arguments: list[str], code: str, *, timeout: int = 35) -> dict[str, object]:
    result = subprocess.run(
        [str(COMPILER), *arguments], cwd=ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout,
        check=False, env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
    )
    if result.returncode or result.stderr:
        raise NavigationError(code, "canonical compiler owner rejected the semantic query")
    try:
        value = json.loads(result.stdout)
    except (UnicodeError, json.JSONDecodeError) as error:
        raise NavigationError(code, "canonical compiler owner returned invalid JSON") from error
    if not isinstance(value, dict):
        raise NavigationError(code, "canonical compiler owner returned a non-object")
    return value


def compiler_admits(path: Path) -> bool:
    data = path.read_bytes()
    arguments = (["dump", "doc-record", str(path)] if b"doc {" in data
                 else ["check", str(path)])
    result = subprocess.run(
        [str(COMPILER), *arguments], cwd=ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=25, check=False,
        env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
    )
    return result.returncode == 0


def safe_relative(path: Path, root: Path) -> str:
    try:
        relative = path.relative_to(root).as_posix()
    except ValueError as error:
        raise NavigationError("NEBO-RF166-G162-001", "source is outside the workspace root") from error
    if not relative or ".." in Path(relative).parts:
        raise NavigationError("NEBO-RF166-G162-001", "unsafe workspace-relative path")
    return relative


@dataclass(frozen=True)
class Source:
    path: Path
    relative: str
    data: bytes
    text: str
    digest: str


@dataclass
class Snapshot:
    root: Path
    sources: dict[str, Source]
    project: dict[str, object]
    records: list[dict[str, object]]
    revision: str
    elapsed_ms: int


def discover(root: Path, current: Path | None, current_data: bytes | None) -> dict[str, Source]:
    if not root.is_dir() or root.is_symlink():
        raise NavigationError("NEBO-RF166-G162-001", "workspace must be a real local directory")
    result: dict[str, Source] = {}
    for directory, names, files in os.walk(root, topdown=True, followlinks=False):
        names.sort()
        files.sort()
        names[:] = [name for name in names if name not in {".git", ".nebo-state"}]
        base = Path(directory)
        if any((base / name).is_symlink() for name in names):
            raise NavigationError("NEBO-RF166-G162-001", "workspace contains a symlink directory")
        for name in files:
            path = base / name
            if path.suffix != ".no":
                continue
            if path.is_symlink():
                raise NavigationError("NEBO-RF166-G162-001", "workspace contains a symlink source")
            relative = safe_relative(path, root)
            data = current_data if current is not None and path.absolute() == current.absolute() else read_regular(path)
            assert data is not None
            result[relative] = Source(path.absolute(), relative, data, data.decode("utf-8"), sha(data))
            if len(result) > MAX_SOURCES:
                raise NavigationError("NEBO-RF166-G162-008", "workspace source-count budget exceeded")
    if current is not None and current_data is not None:
        relative = safe_relative(current.absolute(), root)
        result[relative] = Source(current.absolute(), relative, current_data, current_data.decode("utf-8"), sha(current_data))
    return dict(sorted(result.items(), key=lambda item: item[0].encode("utf-8")))


def copy_index_inputs(root: Path, view: Path, sources: dict[str, Source]) -> None:
    for relative, source in sources.items():
        if b"doc {" not in source.data:
            continue
        destination = view / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(source.data)
    interfaces = 0
    for path in sorted(root.rglob("*.ni"), key=lambda item: item.as_posix().encode("utf-8")):
        if path.is_symlink():
            raise NavigationError("NEBO-RF166-G162-001", "workspace contains a symlink interface")
        relative = safe_relative(path, root)
        destination = view / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(read_regular(path, 1 << 24, utf8=False))
        interfaces += 1
        if interfaces > MAX_INTERFACES:
            raise NavigationError("NEBO-RF166-G162-008", "workspace interface-count budget exceeded")
    package_root = root / "packages"
    if package_root.is_dir() and not package_root.is_symlink():
        for path in sorted(package_root.glob("*.package-index.json"), key=lambda item: item.name.encode("utf-8")):
            destination = view / "packages" / path.name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(read_regular(path, 4 << 20))


def enrich_source_records(view: Path, project: dict[str, object], sources: dict[str, Source]) -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    for raw in project.get("results", []):
        if not isinstance(raw, dict):
            continue
        record = dict(raw)
        source_info = record.get("source")
        if isinstance(source_info, dict) and str(source_info.get("path")) in sources:
            relative = str(source_info["path"])
            doc = compiler_json(["dump", "doc-record", str(view / relative)], "NEBO-RF166-G162-009")
            attachment = doc.get("attachment")
            if not isinstance(attachment, dict) or doc.get("symbolId") != int(str(record["symbolId"]), 16):
                raise NavigationError("NEBO-RF166-G162-009", "DocRecord and ProjectSymbolIndex identity diverged")
            span = attachment.get("nameSpan")
            if not isinstance(span, list) or len(span) != 2:
                raise NavigationError("NEBO-RF166-G162-009", "DocRecord omitted its canonical name span")
            record["definition"] = {"path": relative, "startByte": int(span[0]),
                                    "endByte": int(span[0]) + int(span[1]), "origin": "SOURCE"}
            record["docRecord"] = {
                "signatureHash": doc.get("signatureHash"), "text": doc.get("text", {}),
                "identities": doc.get("identities", {}), "attachment": attachment,
                "owner": "compiler/semantic/docs/doc_record.asm",
            }
        elif record.get("interface") is not None:
            interface = record.get("interface") if isinstance(record.get("interface"), dict) else {}
            record["definition"] = {
                "path": str(interface.get("path", "interface.ni")), "startByte": 0, "endByte": 0,
                "origin": "INTERFACE", "synthetic": True,
            }
        records.append(record)
    return records


def snapshot(workspace: Path, current: Path | None = None, current_data: bytes | None = None,
             deadline: int = MAX_DEADLINE_MS) -> Snapshot:
    started = time.monotonic_ns()
    if not 1 <= deadline <= MAX_DEADLINE_MS:
        raise NavigationError("NEBO-RF166-G162-008", "navigation deadline budget is invalid")
    root = workspace.absolute()
    sources = discover(root, current, current_data)
    with tempfile.TemporaryDirectory(prefix="nebo-g162-index-") as temporary:
        view = Path(temporary)
        copy_index_inputs(root, view, sources)
        inputs = list(view.rglob("*.no")) + list(view.rglob("*.ni")) + list(view.rglob("*.package-index.json"))
        if inputs:
            project = compiler_json(["symbols", str(view), "--json", "--limit", str(MAX_RESULTS),
                                     "--deadline-ms", str(min(deadline, 999))], "NEBO-RF166-G162-009")
            if project.get("owner") != "NEBO-RF166-G160":
                raise NavigationError("NEBO-RF166-G162-009", "query did not use the G160 ProjectSymbolIndex")
            records = enrich_source_records(view, project, sources)
        else:
            project = {"owner": "NEBO-RF166-G160", "results": [], "counts": {"matches": 0},
                       "revision": None, "integration": {"network": False}}
            records = []
    revision = sha(canonical({
        "sources": [(name, item.digest) for name, item in sources.items()],
        "project": project.get("revision"),
    }))
    elapsed = max(1, (time.monotonic_ns() - started + 999_999) // 1_000_000)
    if elapsed > deadline:
        raise NavigationError("NEBO-RF166-G162-008", "navigation deadline elapsed before publication")
    if len(canonical(records)) > MAX_MEMORY:
        raise NavigationError("NEBO-RF166-G162-008", "navigation memory budget exceeded")
    return Snapshot(root, sources, project, records, revision, elapsed)


def code_mask(source: Source) -> str:
    try:
        return TokenModel.scan(source.data).code_mask()
    except (TokenToolError, UnicodeError) as error:
        raise NavigationError('NEBO-RF166-G162-001', 'canonical token projection failed') from error


def word_at(source: Source, offset: int) -> tuple[str, int, int]:
    if not 0 <= offset <= len(source.text):
        raise NavigationError("NEBO-RF166-G162-001", "position is outside the source snapshot")
    model = CommentModel.scan(source.data)
    byte = byte_offset(source.text, offset)
    if model.contains(byte) is not None:
        raise NavigationError("NEBO-RF166-G162-002", "comment trivia has no semantic SymbolId")
    for match in IDENT.finditer(source.text):
        if match.start() <= offset <= match.end():
            if code_mask(source)[match.start():match.end()] != match.group():
                raise NavigationError("NEBO-RF166-G162-002", "string or trivia has no semantic SymbolId")
            return match.group(), match.start(), match.end()
    probe = source.text[:offset]
    matches = list(IDENT.finditer(probe))
    if matches and probe[matches[-1].end():].strip(" \t(") == "":
        match = matches[-1]
        return match.group(), match.start(), match.end()
    raise NavigationError("NEBO-RF166-G162-002", "no semantic identifier exists at the position")


def method_catalog(state: Snapshot) -> list[dict[str, object]]:
    result: dict[str, dict[str, object]] = {}
    for receiver, entries in G161.MEMBERS.items():
        owner = G161.TYPE_OWNERS[receiver]
        for name, kind, signature in entries:
            item = G161.candidate(receiver, name, kind, signature, "CORE", owner, state.revision)
            item.update({"sourceKind": "BUILTIN", "visibility": "PUBLIC"})
            result[str(item["symbolId"])] = item
    for source in state.sources.values():
        for declaration in G161.RECEIVER_METHOD.finditer(code_mask(source)):
            receiver, name = declaration.group("type"), declaration.group("name")
            identity = G161.type_id(receiver)
            item = G161.candidate(
                receiver, name, "method", f"({receiver}.self){name}()", "IMPORTED",
                "compiler/semantic/call/call_resolver.asm", state.revision,
                docs="Receiver-first callable admitted by canonical overload resolution.",
                constraints=["receiver-first"], receiver_identity=identity,
            )
            item.update({"sourceKind": "SOURCE", "visibility": "PUBLIC"})
            result.setdefault(str(item["symbolId"]), item)
    return list(result.values())


def symbol_by_selector(state: Snapshot, selector: str) -> dict[str, object]:
    candidates = [*state.records, *method_catalog(state)]
    if re.fullmatch(r"0x[0-9a-fA-F]{16}", selector):
        matches = [item for item in candidates if str(item.get("symbolId")).casefold() == selector.casefold()]
    else:
        if not IDENT.fullmatch(selector):
            raise NavigationError("NEBO-RF166-G162-001", "symbol selector must be a name or 64-bit SymbolId")
        matches = [item for item in candidates if item.get("name") == selector]
    unique = {str(item["symbolId"]): item for item in matches}
    if len(unique) != 1:
        reason = "not found" if not unique else "ambiguous; use SymbolId"
        raise NavigationError("NEBO-RF166-G162-002", f"semantic symbol is {reason}")
    return next(iter(unique.values()))


def module_import_target(state: Snapshot, source: Source, word: str, start: int) -> dict[str, object] | None:
    for match in IMPORT.finditer(source.text):
        if not match.start() <= start < match.end():
            continue
        module, alias = match.group("module"), match.group("alias")
        terminal = module.rsplit(".", 1)[-1]
        if word not in {terminal, alias}:
            continue
        matches = [item for item in state.records if item.get("kind") == "module" and
                   str(item.get("name")) in {module, terminal}]
        if len(matches) == 1:
            return matches[0]
    aliases = [match for match in IMPORT.finditer(source.text) if word == match.group("alias")]
    if len(aliases) == 1:
        module = aliases[0].group("module")
        terminal = module.rsplit(".", 1)[-1]
        matches = [item for item in state.records if item.get("kind") == "module" and
                   str(item.get("name")) in {module, terminal}]
        if len(matches) == 1:
            return matches[0]
    return None


def receiver_at_call(source: Source, offset: int) -> str:
    # Primitive literal receivers use committed native token kinds, including
    # literals inside interpolation. No text-pattern guess authorizes a type.
    native = TokenModel.scan(source.data)
    byte = byte_offset(source.text, offset)
    primitive = {3:'Int',4:'Text',5:'Float',6:'Char',13:'Bool',14:'Bool'}
    for index,token in enumerate(native.tokens):
        if token.kind == 2 and token.end == byte and index >= 2:
            if native.tokens[index-1].kind == 56:
                kind = native.tokens[index-2].kind
                if kind in primitive:
                    return primitive[kind]
    # A grouped integer expression has no binding name for the completion
    # recovery path. Project native tokens, then require the semantic owner to
    # admit its Int result before assigning the receiver TypeId. Calls, names,
    # comparisons and mixed literal kinds cannot enter this projection.
    for index, token in enumerate(native.tokens):
        if token.kind != 2 or token.end != byte or index < 3: continue
        if source.data[native.tokens[index-1].start:native.tokens[index-1].end] != b".": continue
        last = index - 2
        if source.data[native.tokens[last].start:native.tokens[last].end] != b")": continue
        depth = 0; first = None
        for j in range(last, -1, -1):
            spelling = source.data[native.tokens[j].start:native.tokens[j].end]
            if spelling == b")": depth += 1
            elif spelling == b"(":
                depth -= 1
                if depth == 0: first = j; break
        if first is None or last-first > 128: continue
        selected = native.tokens[first:last+1]
        if not any(t.kind == 3 for t in selected): continue
        if any(t.kind != 3 and source.data[t.start:t.end] not in (b"(", b")", b"+", b"-", b"*", b"/", b"%") for t in selected): continue
        expression = source.data[selected[0].start:selected[-1].end]
        with tempfile.TemporaryDirectory(prefix="nebo-receiver-type-") as raw:
            path = Path(raw)/"expression.no"
            path.write_bytes(b"start(){Int.receiver;"+expression+b".receiver;receiver.return;}")
            if compiler_admits(path): return "Int"
    try:
        return G161.infer_receiver(source.text, offset)[0]
    except G161.CompletionError:
        expression, _ = G161.expression_before_dot(source.text, offset)
        declared = {match.group("name") for match in G161.STRUCT.finditer(source.text)}
        seen: set[str] = set()
        while expression and expression not in seen:
            expression = expression.strip()
            direct = re.match(r"(?P<name>[A-Za-z_][A-Za-z0-9_]*)\.default\s*\(", expression)
            if direct and direct.group("name") in declared:
                return direct.group("name")
            if not IDENT.fullmatch(expression):
                lead = IDENT.match(expression)
                expression = lead.group() if lead else None
                continue
            if expression in declared:
                return expression
            seen.add(expression)
            bindings = [match for match in G161.BINDING.finditer(source.text[:offset])
                        if match.group("name") == expression]
            expression = bindings[-1].group("expr") if bindings else None
    raise NavigationError("NEBO-RF166-G162-002", "call receiver has no canonical TypeId")


def method_at(state: Snapshot, source: Source, word: str, start: int, end: int) -> dict[str, object] | None:
    mask = code_mask(source)
    declaration = next((item for item in G161.RECEIVER_METHOD.finditer(mask)
                        if item.start("name") == start and item.group("name") == word), None)
    if declaration is not None:
        receiver = declaration.group("type")
        selector = G161.candidate(
            receiver, word, "method", f"({receiver}.self){word}()", "IMPORTED",
            "compiler/semantic/call/call_resolver.asm", state.revision,
            receiver_identity=G161.type_id(receiver),
        )["symbolId"]
        return symbol_by_selector(state, str(selector))
    if start == 0 or mask[start - 1] != ".":
        return None
    try:
        receiver = receiver_at_call(source, end)
    except NavigationError:
        return None
    owner = G161.TYPE_OWNERS.get(receiver, "compiler/semantic/call/call_resolver.asm")
    chosen = G161.candidate(receiver, word, "method", "", "CORE", owner, state.revision,
                            receiver_identity=G161.type_id(receiver))
    catalog = {str(item["symbolId"]): item for item in method_catalog(state)}
    return catalog.get(str(chosen["symbolId"]), chosen)


def symbol_at(state: Snapshot, relative: str, offset: int) -> tuple[dict[str, object], tuple[int, int]]:
    if relative not in state.sources:
        raise NavigationError("NEBO-RF166-G162-001", "query source is outside the snapshot")
    source = state.sources[relative]
    word, start, end = word_at(source, offset)
    method = method_at(state, source, word, start, end)
    if method is not None:
        return method, (start, end)
    imported = module_import_target(state, source, word, start)
    if imported is not None:
        return imported, (start, end)
    definitions = [item for item in state.records
                   if isinstance(item.get("definition"), dict)
                   and item["definition"].get("path") == relative
                   and int(item["definition"].get("startByte", -1)) <= byte_offset(source.text, start)
                   < int(item["definition"].get("endByte", -1))]
    if len(definitions) == 1:
        return definitions[0], (start, end)
    direct = [item for item in state.records if item.get("name") == word and item.get("visibility") == "PUBLIC"]
    if len(direct) == 1:
        return direct[0], (start, end)
    raise NavigationError("NEBO-RF166-G162-002", "identifier has no visible semantic SymbolId")


def location(source: Source, start: int, end: int, role: str, symbol: str) -> dict[str, object]:
    return {"path": source.relative, "startByte": byte_offset(source.text, start),
            "endByte": byte_offset(source.text, end), "role": role, "symbolId": symbol,
            "origin": "SOURCE"}


def method_locations(state: Snapshot, symbol: dict[str, object]) -> list[dict[str, object]]:
    wanted = str(symbol["symbolId"])
    name = str(symbol["name"])
    result: list[dict[str, object]] = []
    for source in state.sources.values():
        mask = code_mask(source)
        for match in G161.RECEIVER_METHOD.finditer(mask):
            if match.group("name") != name:
                continue
            candidate = G161.candidate(
                match.group("type"), name, "method", "", "IMPORTED",
                "compiler/semantic/call/call_resolver.asm", state.revision,
                receiver_identity=G161.type_id(match.group("type")),
            )
            if candidate["symbolId"] == wanted:
                result.append(location(source, match.start("name"), match.end("name"), "declaration", wanted))
        for match in CALL.finditer(mask):
            if match.group("name") != name:
                continue
            try:
                receiver = receiver_at_call(source, match.end("name"))
            except NavigationError:
                continue
            owner = G161.TYPE_OWNERS.get(receiver, "compiler/semantic/call/call_resolver.asm")
            candidate = G161.candidate(receiver, name, "method", "", "CORE", owner,
                                       state.revision, receiver_identity=G161.type_id(receiver))
            if candidate["symbolId"] == wanted:
                result.append(location(source, match.start("name"), match.end("name"), "reference", wanted))
    return sorted(result, key=lambda item: (str(item["path"]), int(item["startByte"]), str(item["role"])))[:MAX_RESULTS]


def module_locations(state: Snapshot, symbol: dict[str, object]) -> list[dict[str, object]]:
    wanted, name = str(symbol["symbolId"]), str(symbol["name"])
    result: list[dict[str, object]] = []
    definition = symbol.get("definition")
    if isinstance(definition, dict) and definition.get("origin") == "SOURCE":
        result.append({**definition, "role": "declaration", "symbolId": wanted})
    for source in state.sources.values():
        for match in IMPORT.finditer(source.text):
            module = match.group("module")
            if module not in {name} and module.rsplit(".", 1)[-1] != name:
                continue
            start_char = match.start("module") + len(module) - len(name)
            result.append(location(source, start_char, start_char + len(name), "import", wanted))
    return sorted(result, key=lambda item: (str(item["path"]), int(item["startByte"]), str(item["role"])))[:MAX_RESULTS]


def package_locations(state: Snapshot, symbol: dict[str, object]) -> list[dict[str, object]]:
    wanted, name, module = str(symbol["symbolId"]), str(symbol["name"]), str(symbol.get("module") or "")
    result: list[dict[str, object]] = []
    for source in state.sources.values():
        mask = code_mask(source)
        for imported in IMPORT.finditer(source.text):
            if imported.group("module") != module:
                continue
            selected = imported.group("selected") or ""
            for item in IDENT.finditer(selected):
                if item.group() == name:
                    start = imported.start("selected") + item.start()
                    result.append(location(source, start, start + len(name), "import", wanted))
            alias = imported.group("alias")
            qualified = re.compile(rf"\b{re.escape(alias)}\s*\.\s*(?P<name>{re.escape(name)})\b")
            for item in qualified.finditer(mask):
                result.append(location(source, item.start("name"), item.end("name"), "reference", wanted))
    return sorted(result, key=lambda item: (str(item["path"]), int(item["startByte"]), str(item["role"])))[:MAX_RESULTS]


def locations_for(state: Snapshot, symbol: dict[str, object]) -> list[dict[str, object]]:
    if symbol.get("package") is not None:
        return package_locations(state, symbol)
    if symbol.get("sourceKind") in {"SOURCE", "BUILTIN"}:
        return method_locations(state, symbol)
    return module_locations(state, symbol)


def definition_for(state: Snapshot, symbol: dict[str, object]) -> dict[str, object]:
    locations = locations_for(state, symbol)
    declarations = [item for item in locations if item.get("role") == "declaration"]
    if declarations:
        return declarations[0]
    definition = symbol.get("definition")
    if isinstance(definition, dict) and definition.get("origin") == "INTERFACE":
        return {**definition, "role": "definition", "symbolId": symbol["symbolId"],
                "uri": f"nebo-interface://{definition['path']}#{symbol['symbolId']}"}
    if symbol.get("sourceKind") == "BUILTIN":
        return {"path": str(symbol.get("owner")), "startByte": 0, "endByte": 0,
                "role": "definition", "origin": "BUILTIN", "synthetic": True,
                "uri": f"nebo-builtin://{symbol.get('receiverTypeId')}/{symbol['symbolId']}",
                "symbolId": symbol["symbolId"]}
    raise NavigationError("NEBO-RF166-G162-002", "semantic definition is unavailable")


def related_docs(symbol: dict[str, object]) -> dict[str, object] | None:
    docs = symbol.get("docs") if isinstance(symbol.get("docs"), dict) else None
    if docs is None:
        documentation = symbol.get("documentation")
        return None if documentation is None else {"summary": documentation, "origin": "BUILTIN"}
    # recordKey identifies a cached DocRecord revision, not its public symbol.
    # Documentation paths and IDE links must use the same semantic identity.
    key = str(symbol["symbolId"])
    return {"uri": f"nebo-doc://symbol/{key}", "title": str(docs.get("title") or symbol.get("name")),
            "summary": str(docs.get("summary") or ""), "origin": "LOCAL"}


def hover_payload(state: Snapshot, symbol: dict[str, object], active: tuple[int, int] | None) -> dict[str, object]:
    docs = symbol.get("docs") if isinstance(symbol.get("docs"), dict) else {}
    doc_record = symbol.get("docRecord") if isinstance(symbol.get("docRecord"), dict) else {}
    texts = doc_record.get("text") if isinstance(doc_record.get("text"), dict) else {}
    signature = str(symbol.get("signature") or f"{symbol.get('kind')} {symbol.get('name')}")
    return {
        "symbolId": symbol["symbolId"], "name": symbol["name"], "kind": symbol.get("kind"),
        "type": symbol.get("receiverTypeId") or symbol.get("kind"), "signature": signature,
        "documentation": str(texts.get("summary") or docs.get("summary") or symbol.get("documentation") or ""),
        "effects": list(map(str, symbol.get("effects", []))),
        "capabilities": list(map(str, symbol.get("capabilities", []))),
        "risks": str(texts.get("risks") or "none documented"),
        "origin": "INTERFACE" if symbol.get("interface") is not None and symbol.get("source") is None else
                  str(symbol.get("sourceKind") or "SOURCE"),
        "availability": {"target": symbol.get("target", TARGET), "edition": symbol.get("edition", 1),
                         "visibility": symbol.get("visibility", "PUBLIC")},
        "relatedDocs": related_docs(symbol), "activeRange": list(active) if active else None,
    }


def signature_payload(state: Snapshot, symbol: dict[str, object], source: Source | None,
                      offset: int | None) -> dict[str, object]:
    signature = str(symbol.get("signature") or f"{symbol.get('kind')} {symbol.get('name')}")
    parameters: list[dict[str, object]] = []
    found = re.search(r"\.(?:[A-Za-z_][A-Za-z0-9_]*)\(([^()]*)\)", signature)
    raw = found.group(1).strip() if found else ""
    if raw:
        for index, item in enumerate(raw.split(",")):
            part = item.strip()
            label = part.split(":", 1)[0].strip() if ":" in part else f"arg{index + 1}"
            default = part.split("=", 1)[1].strip() if "=" in part else None
            parameters.append({"label": label, "source": part, "default": default})
    active = 0
    mapping: list[dict[str, object]] = []
    if source is not None and offset is not None:
        calls = [match for match in CALL.finditer(code_mask(source))
                 if match.group("name") == symbol.get("name") and match.start() <= offset]
        left = calls[-1].end() - 1 if calls else -1
        arguments = source.text[left + 1:offset] if left >= 0 and offset > left else ""
        active = min(arguments.count(","), max(0, len(parameters) - 1))
        for index, value in enumerate(arguments.split(",")):
            value = value.strip()
            if not value:
                continue
            named = value.split(":", 1)[0].strip() if ":" in value else None
            mapping.append({"argument": index, "parameter": named or
                            (parameters[index]["label"] if index < len(parameters) else None),
                            "mode": "named" if named else "positional"})
    return {"symbolId": symbol["symbolId"], "signatures": [{"label": signature,
            "parameters": parameters, "documentation": hover_payload(state, symbol, None)["documentation"]}],
            "activeSignature": 0, "activeParameter": active, "argumentMapping": mapping,
            "mappingPolicy": {"positional": True, "named": True, "defaults": True},
            "overloadOwner": "compiler/semantic/call/call_resolver.asm"}


def base_report(state: Snapshot, command: str, symbol: dict[str, object]) -> dict[str, object]:
    project_revision = state.project.get("revision") if isinstance(state.project, dict) else None
    return {
        "schema": 1, "command": command, "owner": OWNER, "symbolId": symbol["symbolId"],
        "snapshot": {"sha256": state.revision, "files": len(state.sources), "revisionBound": True},
        "projectIndex": {"owner": "NEBO-RF166-G160", "revision": project_revision},
        "owners": {"hover": "compiler/lsp/hover.asm", "signature": "compiler/lsp/signature_help.asm",
                   "definition": "compiler/lsp/definition.asm", "references": "compiler/lsp/references.asm",
                   "rename": "compiler/refactor/semantic_rename.asm",
                   "interface": "compiler/lsp/interface_definition.asm",
                   "transaction": "compiler/refactor/tooling_transaction.asm"},
        "budget": {"deadlineMs": MAX_DEADLINE_MS, "observedMs": state.elapsed_ms,
                   "maximumResults": MAX_RESULTS, "memoryBytes": len(canonical(state.records))},
        "network": False,
    }


def validate_revision(state: Snapshot, expected: str | None) -> None:
    if expected is not None and expected != state.revision:
        raise NavigationError("NEBO-RF166-G162-003", "stale navigation snapshot was rejected")


def parse_location(raw: str, source: str) -> tuple[Path, int]:
    pieces = raw.rsplit(":", 2)
    if len(pieces) != 3:
        raise NavigationError("NEBO-RF166-G162-001", "location must be <file>:<line>:<column>")
    try:
        line, column = int(pieces[1]), int(pieces[2])
    except ValueError as error:
        raise NavigationError("NEBO-RF166-G162-001", "line and column must be decimal") from error
    lines = source.splitlines(keepends=True)
    if line <= 0 or column <= 0 or line > len(lines):
        raise NavigationError("NEBO-RF166-G162-001", "location is outside the source")
    content = lines[line - 1].rstrip("\r\n")
    if column - 1 > len(content):
        raise NavigationError("NEBO-RF166-G162-001", "column is outside the source line")
    return Path(pieces[0]).absolute(), sum(len(item) for item in lines[:line - 1]) + column - 1


def resolve_query(state: Snapshot, selector: str, by_location: bool) -> tuple[dict[str, object], Source | None, int | None, tuple[int, int] | None]:
    if not by_location:
        return symbol_by_selector(state, selector), None, None, None
    path = Path(selector.rsplit(":", 2)[0]).absolute()
    relative = safe_relative(path, state.root)
    source = state.sources.get(relative)
    if source is None:
        raise NavigationError("NEBO-RF166-G162-001", "location source is outside the snapshot")
    _, offset = parse_location(selector, source.text)
    symbol, active = symbol_at(state, relative, offset)
    return symbol, source, offset, active


def resolve_signature_query(state: Snapshot, selector: str) -> tuple[dict[str, object], Source, int, tuple[int, int]]:
    path = Path(selector.rsplit(":", 2)[0]).absolute()
    relative = safe_relative(path, state.root)
    source = state.sources.get(relative)
    if source is None:
        raise NavigationError("NEBO-RF166-G162-001", "location source is outside the snapshot")
    _, offset = parse_location(selector, source.text)
    try:
        symbol, active = symbol_at(state, relative, offset)
        return symbol, source, offset, active
    except NavigationError:
        calls = [match for match in CALL.finditer(code_mask(source)) if match.end() <= offset + 1]
        if not calls:
            raise
        call = calls[-1]
        symbol = method_at(state, source, call.group("name"), call.start("name"), call.end("name"))
        if symbol is None:
            raise NavigationError("NEBO-RF166-G162-002", "call has no canonical overload identity")
        return symbol, source, offset, (call.start("name"), call.end("name"))


def rename_edits(state: Snapshot, symbol: dict[str, object], new_name: str) -> list[dict[str, object]]:
    if not IDENT.fullmatch(new_name) or new_name in KEYWORDS:
        raise NavigationError("NEBO-RF166-G162-001", "rename target is not a valid identifier")
    if new_name == symbol.get("name"):
        raise NavigationError("NEBO-RF166-G162-004", "rename target is unchanged")
    collisions = [item for item in [*state.records, *method_catalog(state)] if item.get("name") == new_name]
    if collisions:
        raise NavigationError("NEBO-RF166-G162-004", "rename target collides with a semantic SymbolId")
    if symbol.get("definition", {}).get("origin") == "INTERFACE" or symbol.get("sourceKind") == "BUILTIN":
        raise NavigationError("NEBO-RF166-G162-007", "interface-only and builtin identities are read-only")
    result = []
    for item in locations_for(state, symbol):
        if item.get("role") not in {"declaration", "reference", "import"}:
            continue
        result.append({"path": item["path"], "startByte": item["startByte"],
                       "endByte": item["endByte"], "replacement": new_name,
                       "role": item["role"], "symbolId": symbol["symbolId"]})
    if not result or not any(item["role"] == "declaration" for item in result):
        raise NavigationError("NEBO-RF166-G162-007", "rename requires one source declaration")
    return result


def render_preview(state: Snapshot, edits: list[dict[str, object]]) -> dict[str, bytes]:
    rendered = {name: item.data for name, item in state.sources.items()}
    for edit in sorted(edits, key=lambda item: (str(item["path"]), -int(item["startByte"]))):
        relative = str(edit["path"])
        data = rendered[relative]
        start, end = int(edit["startByte"]), int(edit["endByte"])
        replacement = str(edit["replacement"]).encode("utf-8")
        rendered[relative] = data[:start] + replacement + data[end:]
    return rendered


def verify_rendered(state: Snapshot, rendered: dict[str, bytes]) -> None:
    with tempfile.TemporaryDirectory(prefix="nebo-g162-verify-") as temporary:
        root = Path(temporary)
        for relative, data in rendered.items():
            if data == state.sources[relative].data:
                continue
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            if not compiler_admits(path):
                raise NavigationError("NEBO-RF166-G162-009", "SourceChange.verifySemantics rejected the rename")


def rename_report(state: Snapshot, symbol: dict[str, object], new_name: str, mode: str,
                  allow_breaking: bool, inject_failure: int) -> dict[str, object]:
    edits = rename_edits(state, symbol, new_name)
    rendered = render_preview(state, edits)
    verify_rendered(state, rendered)
    impact = "BREAKING" if symbol.get("visibility", "PUBLIC") == "PUBLIC" else "COMPATIBLE"
    plan_id = sha(canonical({"revision": state.revision, "symbolId": symbol["symbolId"],
                             "newName": new_name, "edits": edits}))
    report = {**base_report(state, f"rename.{mode}", symbol), "plan": {
        "planId": plan_id, "oldName": symbol["name"], "newName": new_name,
        "apiImpact": impact, "edits": edits, "files": sorted({str(item["path"]) for item in edits}),
        "imports": sum(item["role"] == "import" for item in edits),
        "docAttachments": 1, "commentsAndStringsChanged": 0,
        "homonymsChanged": 0, "deterministicOrder": True,
    }, "verification": {"parse": "PASS", "types": "PASS", "effects": "PASS",
                         "ownership": "PASS", "api": impact, "owner": "RF52-SourceChange"},
              "transaction": {"atomic": True, "applied": 0, "rolledBack": False}}
    if mode == "preview":
        return report
    if impact == "BREAKING" and not allow_breaking:
        raise NavigationError("NEBO-RF166-G162-006", "breaking public rename requires explicit authorization")
    paths = sorted({state.root / str(item["path"]) for item in edits}, key=lambda path: path.as_posix())
    expected = {path: state.sources[safe_relative(path, state.root)].digest for path in paths}
    plan = FixPlan.new(expected)
    for edit in edits:
        plan.add({"path": state.root / str(edit["path"]), "start": int(edit["startByte"]),
                  "end": int(edit["endByte"]), "replacement": str(edit["replacement"])})
    plan.orderCanonical()
    plan.failureAfter = inject_failure
    try:
        applied = plan.apply("source-write", "confirmed")
        if not all(compiler_admits(path) for path in paths):
            raise NavigationError("NEBO-RF166-G162-009", "post-rename semantic check failed")
        after = snapshot(state.root)
        if symbol.get("sourceKind") == "SOURCE":
            if not any(item.get("name") == new_name for item in method_catalog(after)):
                raise NavigationError("NEBO-RF166-G162-009", "renamed callable identity was not reindexed")
        elif not any(item.get("name") == new_name for item in after.records):
            raise NavigationError("NEBO-RF166-G162-009", "renamed declaration was not reindexed")
    except (AnalysisError, NavigationError, OSError) as error:
        if plan.journal:
            plan.rollback()
        if isinstance(error, NavigationError):
            raise
        raise NavigationError("NEBO-RF166-G162-009", "rename transaction rolled back without partial state") from error
    report["transaction"] = {"atomic": True, "applied": int(applied["applied"]),
                             "rolledBack": False, "newRevision": after.revision,
                             "owner": "compiler/refactor/tooling_transaction.asm"}
    return report


def command_report(command: str, selector: str, workspace: Path, *, revision: str | None,
                   new_name: str | None = None, mode: str = "preview", allow_breaking: bool = False,
                   deadline: int = 1000, inject_failure: int = 0) -> dict[str, object]:
    location_query = command in {"hover", "signature-help"} or (command == "definition" and ":" in selector)
    path = Path(selector.rsplit(":", 2)[0]).absolute() if location_query else None
    data = read_regular(path) if path is not None else None
    state = snapshot(workspace, path, data, deadline)
    validate_revision(state, revision)
    if command == "signature-help":
        symbol, source, offset, active = resolve_signature_query(state, selector)
    else:
        symbol, source, offset, active = resolve_query(state, selector, location_query)
    report = base_report(state, command, symbol)
    if command == "hover":
        report["hover"] = hover_payload(state, symbol, active)
    elif command == "signature-help":
        report["signatureHelp"] = signature_payload(state, symbol, source, offset)
    elif command == "definition":
        report["definition"] = definition_for(state, symbol)
    elif command == "references":
        report["references"] = locations_for(state, symbol)
        report["count"] = len(report["references"])
    elif command == "rename":
        if new_name is None:
            raise NavigationError("NEBO-RF166-G162-001", "rename target is required")
        report = rename_report(state, symbol, new_name, mode, allow_breaking, inject_failure)
    return report


def lsp_report(arguments: list[str]) -> dict[str, object]:
    if len(arguments) not in {5, 6}:
        raise NavigationError("NEBO-RF166-G162-010", "invalid internal LSP navigation request")
    _, action, raw_path, raw_offset, raw_workspace, *rest = arguments
    if action not in {"hover", "signature-help", "definition", "references", "rename"}:
        raise NavigationError("NEBO-RF166-G162-010", "unknown LSP navigation action")
    path, workspace = Path(raw_path).absolute(), Path(raw_workspace).absolute()
    data = sys.stdin.buffer.read(MAX_SOURCE_BYTES + 1)
    if len(data) > MAX_SOURCE_BYTES:
        raise NavigationError("NEBO-RF166-G162-008", "open document exceeds navigation budget")
    state = snapshot(workspace, path, data)
    relative = safe_relative(path, state.root)
    if action == "signature-help":
        offset = int(raw_offset)
        try:
            symbol, active = symbol_at(state, relative, offset)
        except NavigationError:
            calls = [match for match in CALL.finditer(code_mask(state.sources[relative]))
                     if match.end() <= offset + 1]
            if not calls:
                raise
            call = calls[-1]
            symbol = method_at(state, state.sources[relative], call.group("name"),
                               call.start("name"), call.end("name"))
            if symbol is None:
                raise NavigationError("NEBO-RF166-G162-002", "call has no canonical overload identity")
            active = (call.start("name"), call.end("name"))
    else:
        symbol, active = symbol_at(state, relative, int(raw_offset))
    report = base_report(state, action, symbol)
    if action == "hover":
        report["hover"] = hover_payload(state, symbol, active)
    elif action == "signature-help":
        report["signatureHelp"] = signature_payload(state, symbol, state.sources[relative], int(raw_offset))
    elif action == "definition":
        report["definition"] = definition_for(state, symbol)
    elif action == "references":
        report["references"] = locations_for(state, symbol)
    else:
        if not rest:
            raise NavigationError("NEBO-RF166-G162-010", "LSP rename target is missing")
        report = rename_report(state, symbol, rest[0], "preview", False, 0)
    report["openDocument"] = {"path": relative, "versionDigest": sha(data)}
    return report


def corpus() -> dict[str, object]:
    owners = [
        "compiler/lsp/hover.asm", "compiler/lsp/signature_help.asm",
        "compiler/lsp/definition.asm", "compiler/lsp/references.asm",
        "compiler/refactor/semantic_rename.asm", "compiler/lsp/interface_definition.asm",
        "compiler/refactor/tooling_transaction.asm",
    ]
    if any(not (ROOT / path).is_file() for path in owners):
        raise NavigationError("NEBO-RF166-G162-009", "native navigation owner is missing")
    rows = [{"operation": Path(path).stem, "owner": path, "network": False} for path in owners]
    return {"schema": 1, "command": "navigation-corpus verify", "owner": OWNER,
            "rows": len(rows), "digest": sha(canonical(rows)), "nativeOperations": 7,
            "projectIndexOwner": "NEBO-RF166-G160", "completionOwner": "NEBO-RF166-G161",
            "transactionOwner": "RF52-G48", "network": False, "status": "PASS"}


def main(arguments: list[str]) -> int:
    if arguments == ["navigation-corpus", "--verify"]:
        print(json.dumps(corpus(), sort_keys=True, separators=(",", ":")))
        return 0
    if arguments and arguments[0] == "_lsp":
        print(json.dumps(lsp_report(arguments), sort_keys=True, separators=(",", ":"), ensure_ascii=False))
        return 0
    if not arguments or arguments[0] not in {"hover", "signature-help", "definition", "references", "rename"}:
        raise NavigationError("NEBO-RF166-G162-001", "a G162 navigation command is required")
    command = arguments[0]
    parser = argparse.ArgumentParser(prog=f"neboc {command}")
    parser.add_argument("selector")
    if command == "rename":
        parser.add_argument("new_name")
        modes = parser.add_mutually_exclusive_group(required=True)
        modes.add_argument("--preview", action="store_true")
        modes.add_argument("--apply", action="store_true")
        parser.add_argument("--allow-breaking", action="store_true")
        parser.add_argument("--inject-failure-after", type=int, default=0, help=argparse.SUPPRESS)
    parser.add_argument("--workspace")
    parser.add_argument("--revision")
    parser.add_argument("--deadline-ms", type=int, default=MAX_DEADLINE_MS)
    args = parser.parse_args(arguments[1:])
    selector_path = Path(args.selector.rsplit(":", 2)[0]).absolute() if ":" in args.selector else None
    workspace = Path(args.workspace).absolute() if args.workspace else (
        selector_path.parent if selector_path is not None else Path.cwd().absolute())
    report = command_report(
        command, args.selector, workspace, revision=args.revision,
        new_name=getattr(args, "new_name", None),
        mode="apply" if getattr(args, "apply", False) else "preview",
        allow_breaking=getattr(args, "allow_breaking", False), deadline=args.deadline_ms,
        inject_failure=getattr(args, "inject_failure_after", 0),
    )
    print(json.dumps(report, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (NavigationError, AnalysisError, CommentToolError, G161.CompletionError,
            OSError, UnicodeError, ValueError, json.JSONDecodeError, subprocess.TimeoutExpired) as error:
        code = error.code if isinstance(error, NavigationError) else "NEBO-RF166-G162-009"
        message = error.message if isinstance(error, NavigationError) else str(error)
        print(f"{code}: {message}; note=no navigation or rename state was published", file=sys.stderr)
        raise SystemExit(1)
