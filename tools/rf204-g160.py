#!/usr/bin/env python3
"""Canonical, bounded ProjectSymbolIndex adapter for RF166-G160."""
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
NATIVE = ROOT / "build/bin/nebo-symbol-index"
OWNER = "NEBO-RF166-G160"
PACKAGE_OWNER = "NEBO-RF166-G160-PACKAGE"
TARGET = "x86_64-linux"
MAGIC = 0x303631584449534E
VERSION = 1
MAX_SOURCE_BYTES = 16_384
MAX_INTERFACE_BYTES = 1 << 24
MAX_INDEX_BYTES = 4 << 20
# RF52-G49 owns the semantic query snapshot and admits 32 source units.
MAX_SOURCES = 32
MAX_INTERFACES = 128
MAX_PACKAGES = 64
MAX_ENTRIES = 1024
MAX_RESULTS = 256
MAX_MEMORY = 16 << 20
MAX_DEADLINE = 5_000
ENTRY_COST = 512
MASK64 = (1 << 64) - 1
MANIFEST = "nebo.package.json"
LOCK = "nebo.lock.json"
PACKAGE_STATE = ".nebo-state"
PRELUDE_IDENTITY = "std.prelude:edition-1"

OP_NEW, OP_SOURCE, OP_INTERFACE, OP_WORKSPACE = 1, 2, 3, 4
OP_INCREMENTAL, OP_FILTER, OP_CACHE = 5, 6, 7
FLAG_COLD = 1
FLAG_INCREMENTAL = 2
FLAG_SOURCE_VALIDATED = 4
FLAG_INTERFACE_VALIDATED = 8
FLAG_PACKAGE_LOCAL = 16
FLAG_PRIVATE_FILTERED = 32
FLAG_NO_CAPABILITY_GRANT = 64
FLAG_DEADLINE = 128
FLAG_ATOMIC = 256
FLAG_VERIFY = 512


class IndexError(Exception):
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


def text_digest(value: str | None) -> int:
    return fnv(value.casefold().encode("utf-8")) if value else 0


def safe_relative(path: Path, root: Path) -> str:
    try:
        relative = path.relative_to(root).as_posix()
    except ValueError as error:
        raise IndexError("NEBO-RF166-G160-004", "workspace input escaped its local root") from error
    if not relative or relative.startswith("/") or ".." in Path(relative).parts:
        raise IndexError("NEBO-RF166-G160-004", "workspace input has an unsafe relative path")
    return relative


def read_regular(path: Path, maximum: int, code: str) -> bytes:
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK)
    except OSError as error:
        raise IndexError(code, f"cannot open bounded local input: {path.name}") from error
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode) or info.st_size > maximum:
            raise IndexError(code, f"input is not a bounded regular file: {path.name}")
        data = b""
        while len(data) <= maximum:
            chunk = os.read(descriptor, min(65_536, maximum + 1 - len(data)))
            if not chunk:
                break
            data += chunk
        if len(data) > maximum:
            raise IndexError(code, f"input exceeds its byte budget: {path.name}")
        return data
    finally:
        os.close(descriptor)


def compiler_json(arguments: list[str], code: str) -> dict[str, object]:
    result = subprocess.run(
        [str(COMPILER), *arguments], cwd=ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30, check=False,
        env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
    )
    if result.returncode or result.stderr:
        raise IndexError(code, "canonical compiler owner rejected an index input")
    try:
        value = json.loads(result.stdout)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise IndexError(code, "canonical compiler owner returned invalid JSON") from error
    if not isinstance(value, dict):
        raise IndexError(code, "canonical compiler owner returned a non-object record")
    return value


def compiler_success(arguments: list[str], code: str) -> None:
    result = subprocess.run(
        [str(COMPILER), *arguments], cwd=ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30, check=False,
        env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
    )
    if result.returncode or result.stdout or result.stderr:
        raise IndexError(code, "canonical package owner rejected local manifest/lock state")


def rf52_integration(root: Path, source_count: int) -> dict[str, object]:
    daemon = compiler_json(["server", "status"], "NEBO-RF166-G160-008")
    if daemon != {
        "schema": 1, "endpoint": "local://neboc", "network": False, "status": "OFFLINE",
    }:
        raise IndexError("NEBO-RF166-G160-008", "RF52 local daemon state is not snapshot-safe")
    cache: dict[str, object] = {
        "owner": "RF52-G49", "mode": "revision-bound", "sourceEntries": 0,
        "hits": 0, "misses": 0, "snapshot": None,
    }
    if source_count:
        report = compiler_json(["query-report", str(root)], "NEBO-RF166-G160-008")
        reuse = report.get("reuse")
        snapshot = report.get("snapshot")
        if (
            report.get("schema") != 1 or not isinstance(reuse, dict) or not isinstance(snapshot, dict)
            or reuse.get("entries") != source_count or reuse.get("hits") != source_count
            or reuse.get("misses") != source_count or reuse.get("invalidations") != 0
            or snapshot.get("queryCount") != source_count or snapshot.get("revision") != 1
            or not isinstance(snapshot.get("digest"), str) or len(str(snapshot["digest"])) != 64
        ):
            raise IndexError("NEBO-RF166-G160-008", "RF52 semantic query snapshot diverged")
        cache.update({
            "sourceEntries": source_count, "hits": source_count, "misses": source_count,
            "snapshot": snapshot["digest"],
        })
    return {
        "cache": cache,
        "daemon": {
            "owner": "RF52-G49", "mode": "snapshot-only",
            "endpoint": daemon["endpoint"], "status": daemon["status"],
        },
        "network": False,
    }


def package_state_digest(root: Path) -> str:
    manifest = root / MANIFEST
    lock = root / LOCK
    present = [path.exists() or path.is_symlink() for path in (manifest, lock)]
    if not any(present):
        return sha(b"")
    if not all(present):
        raise IndexError("NEBO-RF166-G160-004", "package manifest and lock must be present together")
    compiler_success(["audit", str(root)], "NEBO-RF166-G160-004")
    payload = bytearray()
    for path in (manifest, lock):
        if path.is_symlink() and os.readlink(path) != f"{PACKAGE_STATE}/current/{path.name}":
            raise IndexError("NEBO-RF166-G160-004", "package state link is not canonical")
        try:
            resolved = path.resolve(strict=True)
        except OSError as error:
            raise IndexError("NEBO-RF166-G160-004", "package state link is unresolved") from error
        safe_relative(resolved, root)
        data = read_regular(resolved, MAX_INDEX_BYTES, "NEBO-RF166-G160-004")
        payload += len(path.name).to_bytes(2, "big") + path.name.encode("ascii")
        payload += len(data).to_bytes(8, "big") + data
    return sha(bytes(payload))


def discover(raw: str) -> tuple[Path, list[Path], list[Path], list[Path]]:
    root = Path(raw).absolute()
    if not root.is_dir() or root.is_symlink():
        raise IndexError("NEBO-RF166-G160-004", "workspace must be a real local directory")
    sources: list[Path] = []
    interfaces: list[Path] = []
    packages: list[Path] = []
    for directory, names, files in os.walk(root, topdown=True, followlinks=False):
        base = Path(directory)
        names.sort()
        files.sort()
        names[:] = [name for name in names if name not in {".git", PACKAGE_STATE}]
        for name in names:
            if (base / name).is_symlink():
                raise IndexError("NEBO-RF166-G160-004", "workspace contains a symlink directory")
        for name in files:
            path = base / name
            relative = safe_relative(path, root)
            if base == root and name in {MANIFEST, LOCK}:
                continue
            if path.is_symlink():
                raise IndexError("NEBO-RF166-G160-004", "workspace contains a symlink input")
            if name.endswith(".no"):
                sources.append(path)
            elif name.endswith(".ni"):
                interfaces.append(path)
            elif name.endswith(".package-index.json") and "packages" in Path(relative).parts:
                packages.append(path)
    if not sources and not interfaces and not packages:
        raise IndexError("NEBO-RF166-G160-004", "workspace has no source, interface, or package index")
    if len(sources) > MAX_SOURCES or len(interfaces) > MAX_INTERFACES or len(packages) > MAX_PACKAGES:
        raise IndexError("NEBO-RF166-G160-007", "workspace input-count budget exceeded")
    return root, sources, interfaces, packages


def semantic_set(value: object, empty: set[str]) -> list[str]:
    if not isinstance(value, str):
        return []
    entries = {item.strip().casefold() for item in value.split(";") if item.strip()}
    return sorted(entries - empty)


def source_symbol(path: Path, root: Path) -> dict[str, object]:
    data = read_regular(path, MAX_SOURCE_BYTES, "NEBO-RF166-G160-002")
    try:
        data.decode("utf-8", "strict")
    except UnicodeDecodeError as error:
        raise IndexError("NEBO-RF166-G160-002", "source is not valid UTF-8") from error
    record = compiler_json(["dump", "doc-record", str(path)], "NEBO-RF166-G160-002")
    attachment = record.get("attachment")
    owners = record.get("owners")
    texts = record.get("text")
    project = record.get("projectIndex")
    if (
        record.get("node") != "DocRecord" or record.get("schema") != 1
        or not isinstance(attachment, dict) or not isinstance(owners, dict)
        or not isinstance(texts, dict) or not isinstance(project, dict)
        or owners.get("semantic") != "compiler/semantic/docs/doc_record.asm"
        or project.get("lookup") != "SymbolId"
    ):
        raise IndexError("NEBO-RF166-G160-002", "source did not yield a canonical DocRecord")
    symbol = record.get("symbolId")
    name = attachment.get("name")
    kind = attachment.get("kind")
    span = record.get("sourceSpan")
    if (
        not isinstance(symbol, int) or symbol <= 0 or not isinstance(name, str) or not name
        or not isinstance(kind, str) or not isinstance(span, list) or len(span) != 2
        or any(not isinstance(item, int) or item < 0 for item in span)
    ):
        raise IndexError("NEBO-RF166-G160-002", "source symbol identity or span is invalid")
    relative = safe_relative(path, root)
    receiver = f"0x{symbol:016x}" if kind in {"type", "struct", "enum"} else None
    return {
        "symbolId": f"0x{symbol:016x}", "name": name, "nameDigest": f"0x{fnv(name.encode('utf-8')):016x}",
        "kind": kind, "receiverTypeId": receiver,
        "module": name if kind == "module" else Path(relative).stem,
        "visibility": str(record.get("visibility")), "edition": 1, "target": TARGET,
        "effects": semantic_set(texts.get("effects"), {"pure", "none"}),
        "capabilities": semantic_set(texts.get("capabilities"), {"none"}),
        "constraints": [], "origins": ["SOURCE"],
        "source": {"path": relative, "span": span, "sha256": sha(data)},
        "interface": None, "package": None,
        "docs": {
            "title": str(texts.get("title", "")), "summary": str(texts.get("summary", "")),
            "since": str(texts.get("since", "1.0")).strip('" '),
            "deprecated": str(texts.get("deprecated", "never")).strip('" '),
            "recordKey": str(project.get("key")),
        },
    }


def interface_symbols(path: Path, root: Path) -> list[dict[str, object]]:
    data = read_regular(path, MAX_INTERFACE_BYTES, "NEBO-RF166-G160-003")
    report = compiler_json(["interface", "inspect", str(path), "--json"], "NEBO-RF166-G160-003")
    records = report.get("symbolRecords")
    if (
        report.get("command") != "interface-inspect" or report.get("schema") != 1
        or report.get("target") != "x86_64-systemv-elf-linux"
        or not isinstance(records, list) or len(records) != report.get("exports")
        or len(records) > MAX_ENTRIES
    ):
        raise IndexError("NEBO-RF166-G160-003", "InterfaceReader omitted typed export records")
    relative = safe_relative(path, root)
    result: list[dict[str, object]] = []
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("symbolId"), int):
            raise IndexError("NEBO-RF166-G160-003", "compiled interface export is malformed")
        symbol = int(record["symbolId"])
        if symbol <= 0:
            raise IndexError("NEBO-RF166-G160-003", "compiled interface contains an invalid SymbolId")
        receiver = int(record.get("receiverTypeId", 0))
        name_digest = str(record.get("nameDigest", ""))
        result.append({
            "symbolId": f"0x{symbol:016x}", "name": f"symbol@{name_digest.removeprefix('0x')}",
            "nameDigest": name_digest, "kind": f"interface-kind-{int(record.get('kind', 0))}",
            "receiverTypeId": f"0x{receiver:016x}" if receiver else None,
            "module": f"module@{int(report.get('moduleId', 0)):016x}",
            "visibility": "PUBLIC" if int(record.get("visibility", 0)) == 1 else "PRIVATE",
            "edition": int(report.get("edition", 0)), "target": TARGET,
            "effects": [] if int(record.get("effects", 0)) == 0 else [f"mask:{int(record['effects'])}"],
            "capabilities": [] if int(record.get("capabilities", 0)) == 0 else [f"mask:{int(record['capabilities'])}"],
            "constraints": [], "origins": ["INTERFACE"], "source": None,
            "interface": {
                "path": relative, "contentDigest": str(report.get("contentDigest")),
                "apiFingerprint": str(report.get("apiFingerprint")), "sha256": sha(data),
            },
            "package": None, "docs": None,
        })
    return result


def validate_package_symbol(value: object, package: str, relative: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise IndexError("NEBO-RF166-G160-004", "package index contains a non-object symbol")
    required = {"symbolId", "name", "kind", "module", "visibility", "edition", "target", "effects", "capabilities"}
    if required - value.keys():
        raise IndexError("NEBO-RF166-G160-004", "package symbol omitted required fields")
    try:
        symbol = int(str(value["symbolId"]), 0)
    except (TypeError, ValueError) as error:
        raise IndexError("NEBO-RF166-G160-004", "package SymbolId is invalid") from error
    edition = value["edition"]
    if (
        symbol <= 0 or value["visibility"] not in {"PUBLIC", "PRIVATE"}
        or isinstance(edition, bool) or not isinstance(edition, int) or edition <= 0
    ):
        raise IndexError("NEBO-RF166-G160-004", "package symbol identity or visibility is invalid")
    name = value["name"]
    kind = value["kind"]
    module = value["module"]
    target = value["target"]
    effects = value["effects"]
    capabilities = value["capabilities"]
    constraints = value.get("constraints", [])
    if (
        not all(isinstance(item, str) and item for item in (name, kind, module, target))
        or any("://" in item for item in (name, kind, module, target, package))
        or not isinstance(effects, list) or not isinstance(capabilities, list)
        or not isinstance(constraints, list)
    ):
        raise IndexError("NEBO-RF166-G160-004", "package symbol context is invalid")
    if any(not isinstance(item, str) or not item or "://" in item for item in [*effects, *capabilities, *constraints]):
        raise IndexError("NEBO-RF166-G160-004", "package effect/capability entries are invalid")
    receiver = value.get("receiverTypeId")
    if receiver is not None:
        try:
            receiver_value = int(str(receiver), 0)
        except (TypeError, ValueError) as error:
            raise IndexError("NEBO-RF166-G160-004", "package receiver TypeId is invalid") from error
        if receiver_value <= 0:
            raise IndexError("NEBO-RF166-G160-004", "package receiver TypeId is invalid")
        receiver = f"0x{receiver_value:016x}"
    docs = value.get("docs")
    if docs is not None:
        if (
            not isinstance(docs, dict)
            or any(not isinstance(key, str) or not isinstance(item, str) for key, item in docs.items())
            or any("://" in item or item.startswith("/") for item in docs.values())
        ):
            raise IndexError("NEBO-RF166-G160-004", "package documentation metadata is unsafe")
    return {
        "symbolId": f"0x{symbol:016x}", "name": name,
        "nameDigest": f"0x{fnv(name.encode('utf-8')):016x}", "kind": kind,
        "receiverTypeId": receiver, "module": module,
        "visibility": str(value["visibility"]), "edition": edition,
        "target": target, "effects": sorted({item.casefold() for item in effects}),
        "capabilities": sorted({item.casefold() for item in capabilities}),
        "constraints": sorted({item.casefold() for item in constraints}),
        "origins": ["PACKAGE"], "source": None, "interface": None,
        "package": {"name": package, "index": relative}, "docs": docs,
    }


def package_symbols(path: Path, root: Path) -> list[dict[str, object]]:
    data = read_regular(path, MAX_INDEX_BYTES, "NEBO-RF166-G160-004")
    try:
        value = json.loads(data)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise IndexError("NEBO-RF166-G160-004", "local package index is malformed") from error
    if not isinstance(value, dict) or value.get("schema") != 1 or value.get("owner") != PACKAGE_OWNER:
        raise IndexError("NEBO-RF166-G160-004", "local package index schema or owner is invalid")
    digest = value.get("digest")
    unsigned = {key: item for key, item in value.items() if key != "digest"}
    if digest != sha(canonical(unsigned)):
        raise IndexError("NEBO-RF166-G160-004", "local package index digest is invalid")
    package = value.get("package")
    symbols = value.get("symbols")
    if (
        not isinstance(package, str) or not package or "://" in package
        or not re.fullmatch(r"[A-Za-z0-9_.-]+", package)
        or not isinstance(symbols, list) or len(symbols) > MAX_ENTRIES
    ):
        raise IndexError("NEBO-RF166-G160-004", "local package index metadata is invalid")
    relative = safe_relative(path, root)
    return [validate_package_symbol(item, package, relative) for item in symbols]


def merge_records(records: list[dict[str, object]]) -> list[dict[str, object]]:
    merged: dict[str, dict[str, object]] = {}
    for record in records:
        symbol = str(record["symbolId"])
        current = merged.get(symbol)
        if current is None:
            merged[symbol] = record
            continue
        if current["visibility"] != record["visibility"] or current["nameDigest"] != record["nameDigest"]:
            raise IndexError("NEBO-RF166-G160-001", "one SymbolId resolved to incompatible identities")
        if set(map(str, current["origins"])) & set(map(str, record["origins"])):
            raise IndexError("NEBO-RF166-G160-001", "one index origin published a duplicate SymbolId")
        origins = sorted(set([*current["origins"], *record["origins"]]))
        if "SOURCE" in record["origins"]:
            for key in ("name", "kind", "receiverTypeId", "module", "source", "docs", "effects", "capabilities"):
                current[key] = record[key]
        if record.get("interface") is not None:
            current["interface"] = record["interface"]
        if record.get("package") is not None:
            current["package"] = record["package"]
        current["origins"] = origins
    return sorted(merged.values(), key=lambda item: int(str(item["symbolId"]), 16))


def apply_filters(
    records: list[dict[str, object]], edition: int, target: str,
    effects: set[str], capabilities: set[str], constraints: set[str], name: str | None,
    receiver: str | None, module: str | None, limit: int,
) -> tuple[list[dict[str, object]], int, int]:
    private = sum(record["visibility"] != "PUBLIC" for record in records)
    public = [record for record in records if record["visibility"] == "PUBLIC"]
    eligible: list[dict[str, object]] = []
    policy_filtered = 0
    receiver_key = receiver.casefold() if receiver else None
    for record in public:
        record_effects = set(map(str, record["effects"]))
        record_capabilities = set(map(str, record["capabilities"]))
        record_constraints = set(map(str, record["constraints"]))
        compatible = (
            int(record["edition"]) <= edition
            and record["target"] in {target, "*"}
            and record_effects <= effects
            and record_capabilities <= capabilities
            and record_constraints <= constraints
        )
        if not compatible:
            policy_filtered += 1
            continue
        eligible.append(record)
    queried = eligible
    if name is not None:
        key = name.casefold()
        digest = f"0x{fnv(name.encode('utf-8')):016x}"
        queried = [
            item for item in queried
            if str(item["name"]).casefold() == key or item["nameDigest"] == digest
        ]
    if receiver_key is not None:
        queried = [item for item in queried if str(item.get("receiverTypeId") or "").casefold() == receiver_key]
    if module is not None:
        key = module.casefold()
        queried = [item for item in queried if str(item["module"]).casefold() == key]
    queried.sort(key=lambda item: (str(item["kind"]), str(item["name"]).casefold(), int(str(item["symbolId"]), 16)))
    return queried[:limit], private, policy_filtered


def revision_parts(root: Path, sources: list[Path], interfaces: list[Path], packages: list[Path]) -> dict[str, str]:
    def digest(paths: list[Path], maximum: int, code: str) -> str:
        projection = [
            [safe_relative(path, root), sha(read_regular(path, maximum, code))]
            for path in paths
        ]
        return sha(canonical(projection))
    source = digest(sources, MAX_SOURCE_BYTES, "NEBO-RF166-G160-002")
    interface = digest(interfaces, MAX_INTERFACE_BYTES, "NEBO-RF166-G160-003")
    package = digest(packages, MAX_INDEX_BYTES, "NEBO-RF166-G160-004")
    package_lock = package_state_digest(root)
    prelude = sha(PRELUDE_IDENTITY.encode("ascii"))
    workspace = sha(canonical({
        "source": source, "interface": interface, "package": package,
        "packageLock": package_lock, "prelude": prelude,
    }))
    return {
        "workspace": workspace, "source": source, "interface": interface,
        "packages": package, "packageLock": package_lock, "prelude": prelude,
    }


def request(
    operation: int, facts: dict[str, int], flags: int,
    name: str | None = None, receiver: str | None = None, module: str | None = None,
) -> bytes:
    values = [
        MAGIC, VERSION, operation, flags, facts["workspace"], facts["revision"],
        facts["sources"], facts["interfaces"], facts["packages"], facts["total"],
        facts["public"], facts["private"], facts["results"], text_digest(name),
        text_digest(receiver), text_digest(module), facts["limit"], facts["target"],
        facts["edition"], facts["contextEffects"], facts["contextCapabilities"],
        facts["filtered"], facts["added"], facts["removed"], facts["updated"],
        facts["cold"], facts["incremental"], facts["residentBytes"], facts["memoryBudget"],
        facts["hits"], facts["misses"], facts["evictions"], facts["deadline"], facts["observedMs"], 0, 0,
    ]
    return struct.pack("<36Q", *values)


def native(operation: int, facts: dict[str, int], flags: int, name: str | None = None,
           receiver: str | None = None, module: str | None = None) -> None:
    if not NATIVE.is_file():
        raise IndexError("NEBO-RF166-G160-008", "native ProjectSymbolIndex owner is unavailable")
    result = subprocess.run(
        [str(NATIVE)], input=request(operation, facts, flags, name, receiver, module),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10, check=False,
    )
    if result.returncode or result.stderr or len(result.stdout) != 64:
        raise IndexError("NEBO-RF166-G160-008", f"native ProjectSymbolIndex operation {operation} rejected observed facts")
    words = struct.unpack("<8Q", result.stdout)
    if words[:2] != (0, operation) or words[2] != facts["cold"] or words[3] != facts["total"]:
        raise IndexError("NEBO-RF166-G160-008", "native ProjectSymbolIndex result diverged")
    if words[4] != facts["results"] or words[5] != facts["residentBytes"] or words[6] != facts["revision"]:
        raise IndexError("NEBO-RF166-G160-008", "native ProjectSymbolIndex metrics diverged")


def index_body(value: dict[str, object]) -> dict[str, object]:
    return {key: item for key, item in value.items() if key != "indexDigest"}


def seal(value: dict[str, object]) -> dict[str, object]:
    result = dict(value)
    result["indexDigest"] = sha(canonical(value))
    return result


def load_index(path: Path) -> dict[str, object]:
    data = read_regular(path, MAX_INDEX_BYTES, "NEBO-RF166-G160-005")
    try:
        value = json.loads(data)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise IndexError("NEBO-RF166-G160-005", "ProjectSymbolIndex is malformed") from error
    if not isinstance(value, dict) or value.get("schema") != 1 or value.get("owner") != OWNER:
        raise IndexError("NEBO-RF166-G160-005", "ProjectSymbolIndex schema or owner is invalid")
    if value.get("indexDigest") != sha(canonical(index_body(value))):
        raise IndexError("NEBO-RF166-G160-005", "ProjectSymbolIndex digest is invalid")
    symbols = value.get("symbols")
    if not isinstance(symbols, list) or not symbols or len(symbols) > MAX_ENTRIES:
        raise IndexError("NEBO-RF166-G160-005", "ProjectSymbolIndex symbols are invalid")
    return value


def facts_for(
    raw_counts: tuple[int, int, int], raw: list[dict[str, object]], results: list[dict[str, object]],
    parts: dict[str, str], revision: int, edition: int, target: str, private: int,
    policy_filtered: int, memory_budget: int, deadline: int,
) -> dict[str, int]:
    source_count, interface_count, package_count = raw_counts
    total = len(raw)
    public = total - private
    merged_public = len({str(item["symbolId"]) for item in raw if item["visibility"] == "PUBLIC"})
    coalesced = public - merged_public
    cold = fnv(canonical(results))
    logical_bytes = len(canonical(results))
    resident = min(logical_bytes, memory_budget)
    pressure = max(0, len(results) - memory_budget // ENTRY_COST)
    return {
        "workspace": int(parts["workspace"][:16], 16) or 1, "revision": revision,
        "sources": source_count, "interfaces": interface_count, "packages": package_count,
        "total": total, "public": public, "private": private, "results": len(results),
        "limit": MAX_RESULTS, "target": text_digest(target), "edition": edition,
        "contextEffects": 0, "contextCapabilities": 0,
        "filtered": policy_filtered + coalesced, "added": 0, "removed": 0, "updated": 0,
        "cold": cold, "incremental": cold, "residentBytes": resident,
        "memoryBudget": memory_budget, "hits": 0, "misses": total,
        "evictions": min(total, pressure), "deadline": deadline,
        "observedMs": 1, "logicalBytes": logical_bytes,
    }


def build_index(
    workspace: str, revision_option: int | None, edition: int, target: str,
    effects: set[str], capabilities: set[str], constraints: set[str],
    memory_budget: int, deadline: int,
    name: str | None = None, receiver: str | None = None, module: str | None = None,
    limit: int = MAX_RESULTS,
) -> tuple[
    dict[str, object], dict[str, int], list[dict[str, object]],
    list[dict[str, object]], dict[str, int],
]:
    if edition != 1 or target != TARGET:
        raise IndexError("NEBO-RF166-G160-006", "only Edition 1 and x86_64-linux are supported")
    if not 1 <= limit <= MAX_RESULTS or not 1 <= memory_budget <= MAX_MEMORY or not 1 <= deadline <= MAX_DEADLINE:
        raise IndexError("NEBO-RF166-G160-007", "query, memory, or deadline budget is invalid")
    root, sources, interfaces, packages = discover(workspace)
    source_records = [source_symbol(path, root) for path in sources]
    interface_records = [record for path in interfaces for record in interface_symbols(path, root)]
    package_records = [record for path in packages for record in package_symbols(path, root)]
    integration = rf52_integration(root, len(source_records))
    raw = [*source_records, *interface_records, *package_records]
    if not raw or len(raw) > MAX_ENTRIES:
        raise IndexError("NEBO-RF166-G160-007", "ProjectSymbolIndex entry budget exceeded")
    parts = revision_parts(root, sources, interfaces, packages)
    revision = revision_option if revision_option is not None else int(parts["workspace"][:16], 16) or 1
    if revision <= 0 or revision > MASK64:
        raise IndexError("NEBO-RF166-G160-001", "SymbolIndexRevision must be a nonzero u64")
    merged = merge_records(raw)
    eligible, _merged_private, policy_filtered = apply_filters(
        merged, edition, target, effects, capabilities, constraints, None, None, None, MAX_ENTRIES,
    )
    if not eligible:
        raise IndexError("NEBO-RF166-G160-006", "context filters removed every public symbol")
    query_started = time.monotonic_ns()
    results, _private, _query_filtered = apply_filters(
        merged, edition, target, effects, capabilities, constraints, name, receiver, module, limit,
    )
    observed_ms = max(1, (time.monotonic_ns() - query_started + 999_999) // 1_000_000)
    if observed_ms > deadline:
        raise IndexError("NEBO-RF166-G160-007", "query deadline exceeded before publication")
    private = sum(item["visibility"] != "PUBLIC" for item in raw)
    counts = (len(source_records), len(interface_records), len(package_records))
    facts = facts_for(counts, raw, eligible, parts, revision, edition, target, private, policy_filtered, memory_budget, deadline)
    facts["limit"] = MAX_RESULTS
    facts["contextEffects"] = fnv(canonical(sorted(effects)))
    facts["contextCapabilities"] = fnv(canonical({
        "capabilities": sorted(capabilities), "constraints": sorted(constraints),
    }))
    flags = FLAG_COLD | FLAG_PRIVATE_FILTERED | FLAG_NO_CAPABILITY_GRANT | FLAG_DEADLINE | FLAG_ATOMIC
    if source_records:
        flags |= FLAG_SOURCE_VALIDATED
    if interface_records:
        flags |= FLAG_INTERFACE_VALIDATED
    if package_records:
        flags |= FLAG_PACKAGE_LOCAL
    base: dict[str, object] = {
        "schema": 1, "owner": OWNER, "workspace": root.name,
        "revision": {"number": revision, **parts}, "edition": edition, "target": target,
        "counts": {
            "source": len(source_records), "interface": len(interface_records),
            "package": len(package_records), "input": len(raw), "indexed": len(eligible),
            "privateRejected": private, "policyFiltered": policy_filtered,
            "identityMerged": len(raw) - len(merged),
        },
        "context": {
            "effects": sorted(effects), "capabilities": sorted(capabilities),
            "constraints": sorted(constraints), "grants": [],
        },
        "symbols": eligible, "symbolOrder": "kind,name,SymbolId",
        "memoryReport": {
            "entries": len(eligible), "logicalBytes": facts["logicalBytes"],
            "residentBytes": facts["residentBytes"], "budgetBytes": memory_budget,
            "evictions": facts["evictions"],
        },
        "integration": integration,
        "buildPolicy": {"deadlineMs": deadline, "maximumEntries": MAX_ENTRIES},
        "owners": {
            "source": "compiler/semantic/docs/doc_record.asm",
            "interface": "compiler/interface/interface_reader.asm",
            "index": "compiler/semantic/index/project_symbol_index.asm",
            "queryCache": "compiler/sdk/compiler_performance.py",
            "daemon": "compiler/scheduler/local_daemon.asm",
        },
    }
    index = seal(base)
    facts["cold"] = fnv(canonical(index["symbols"]))
    facts["incremental"] = facts["cold"]
    native(OP_NEW, facts, flags)
    if source_records:
        native(OP_SOURCE, facts, flags)
    if interface_records:
        native(OP_INTERFACE, facts, flags)
    native(OP_WORKSPACE, facts, flags)
    query_facts = dict(facts)
    query_facts["results"] = len(results)
    query_facts["limit"] = limit
    query_facts["observedMs"] = observed_ms
    native(OP_FILTER, query_facts, flags, name, receiver, module)
    return index, facts, raw, results, query_facts


def delta(prior: dict[str, object] | None, current: dict[str, object]) -> tuple[dict[str, int], list[dict[str, object]]]:
    old_symbols = [] if prior is None else list(prior["symbols"])
    new_symbols = list(current["symbols"])
    old = {str(item["symbolId"]): item for item in old_symbols}
    new = {str(item["symbolId"]): item for item in new_symbols}
    added = sorted(set(new) - set(old), key=lambda value: int(value, 16))
    removed = sorted(set(old) - set(new), key=lambda value: int(value, 16))
    updated = sorted(
        (symbol for symbol in set(old) & set(new) if canonical(old[symbol]) != canonical(new[symbol])),
        key=lambda value: int(value, 16),
    )
    applied = dict(old)
    for symbol in [*removed, *updated]:
        applied.pop(symbol, None)
    for symbol in [*added, *updated]:
        applied[symbol] = new[symbol]
    rebuilt = sorted(applied.values(), key=lambda item: (str(item["kind"]), str(item["name"]).casefold(), int(str(item["symbolId"]), 16)))
    if canonical(rebuilt) != canonical(new_symbols):
        raise IndexError("NEBO-RF166-G160-005", "incremental application diverged from cold order")
    return {"added": len(added), "removed": len(removed), "updated": len(updated)}, rebuilt


def atomic_write(path: Path, data: bytes) -> None:
    path = path.absolute()
    if not path.parent.is_dir() or path.parent.is_symlink():
        raise IndexError("NEBO-RF166-G160-008", "index output parent must be a real directory")
    if path.exists() and (path.is_symlink() or not path.is_file()):
        raise IndexError("NEBO-RF166-G160-008", "index output must be a regular file")
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, path)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--revision", type=int)
    parser.add_argument("--edition", type=int, default=1)
    parser.add_argument("--target", default=TARGET)
    parser.add_argument("--context-effect", action="append", default=[])
    parser.add_argument("--context-capability", action="append", default=[])
    parser.add_argument("--context-constraint", action="append", default=[])
    parser.add_argument("--memory-budget", type=int, default=MAX_MEMORY)
    parser.add_argument("--deadline-ms", type=int, default=1_000)


def symbols_command(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc symbols")
    parser.add_argument("workspace")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--index")
    parser.add_argument("--name")
    parser.add_argument("--receiver")
    parser.add_argument("--module")
    parser.add_argument("--limit", type=int, default=MAX_RESULTS)
    options(parser)
    args = parser.parse_args(arguments)
    index, _build_facts, _raw, results, facts = build_index(
        args.workspace, args.revision, args.edition, args.target,
        set(args.context_effect), set(args.context_capability), set(args.context_constraint), args.memory_budget,
        args.deadline_ms, args.name, args.receiver, args.module, args.limit,
    )
    if args.index:
        persisted = load_index(Path(args.index))
        if persisted["revision"] != index["revision"] or persisted["symbols"] != index["symbols"]:
            raise IndexError("NEBO-RF166-G160-005", "stale revision cannot answer a symbol query")
        facts["hits"], facts["misses"] = facts["total"], 0
    native(OP_CACHE, facts, FLAG_COLD | FLAG_ATOMIC | FLAG_DEADLINE)
    report = {
        "schema": 1, "command": "symbols", "owner": OWNER,
        "workspace": index["workspace"], "revision": index["revision"],
        "indexDigest": index["indexDigest"],
        "counts": {**index["counts"], "matches": len(results)},
        "context": index["context"],
        "query": {
            "name": args.name, "receiverTypeId": args.receiver,
            "module": args.module, "limit": args.limit, "deadlineMs": args.deadline_ms,
        },
        "results": results, "symbolOrder": index["symbolOrder"],
        "memoryReport": index["memoryReport"], "integration": index["integration"],
        "owners": index["owners"],
    }
    if args.json:
        print(json.dumps(report, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    else:
        for record in results:
            print(f"{record['symbolId']}\t{record['kind']}\t{record['name']}\t{record['module']}\t{'+'.join(record['origins'])}")
    return 0


def index_command(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc symbol-index")
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--rebuild", action="store_true")
    action.add_argument("--verify", action="store_true")
    parser.add_argument("workspace")
    parser.add_argument("-o", "--output")
    parser.add_argument("--index")
    options(parser)
    args = parser.parse_args(arguments)
    if args.rebuild == (args.output is None) or args.verify == (args.index is None):
        raise IndexError("NEBO-RF166-G160-008", "rebuild requires -o and verify requires --index")
    current, facts, _raw, _results, _query_facts = build_index(
        args.workspace, args.revision, args.edition, args.target,
        set(args.context_effect), set(args.context_capability), set(args.context_constraint),
        args.memory_budget, args.deadline_ms,
    )
    prior: dict[str, object] | None = None
    if args.rebuild and Path(args.output).exists():
        prior = load_index(Path(args.output))
    elif args.verify:
        prior = load_index(Path(args.index))
    changes, rebuilt = delta(prior, current)
    facts.update(changes)
    facts["incremental"] = fnv(canonical(rebuilt))
    if prior is None:
        facts["hits"], facts["misses"] = 0, facts["total"]
    else:
        facts["misses"] = min(facts["total"], changes["added"] + changes["updated"])
        facts["hits"] = facts["total"] - facts["misses"]
    facts["evictions"] = min(facts["total"], changes["removed"] + facts["evictions"])
    incremental_flags = FLAG_INCREMENTAL | FLAG_ATOMIC | FLAG_VERIFY
    native(OP_INCREMENTAL, facts, incremental_flags)
    native(OP_CACHE, facts, FLAG_INCREMENTAL | FLAG_ATOMIC | FLAG_DEADLINE)
    if args.verify:
        if prior is None or prior["revision"] != current["revision"] or prior["symbols"] != current["symbols"] or any(changes.values()):
            raise IndexError("NEBO-RF166-G160-005", "persisted index is stale relative to the cold revision")
    else:
        payload = canonical(current) + b"\n"
        if len(payload) > MAX_INDEX_BYTES:
            raise IndexError("NEBO-RF166-G160-007", "ProjectSymbolIndex output exceeds its byte budget")
        atomic_write(Path(args.output), payload)
    report = {
        "schema": 1, "command": "symbol-index verify" if args.verify else "symbol-index rebuild",
        "revision": current["revision"], "indexDigest": current["indexDigest"],
        "entries": len(current["symbols"]), "delta": changes,
        "coldIncrementalParity": "BYTE_IDENTICAL", "staleRecords": 0,
        "memoryReport": current["memoryReport"], "cache": {"hits": facts["hits"], "misses": facts["misses"], "evictions": facts["evictions"]},
    }
    print(json.dumps(report, sort_keys=True, separators=(",", ":")))
    return 0


def main(arguments: list[str]) -> int:
    if not arguments:
        raise IndexError("NEBO-RF166-G160-008", "symbols or symbol-index command required")
    command, rest = arguments[0], arguments[1:]
    if command == "symbols":
        return symbols_command(rest)
    if command == "symbol-index":
        return index_command(rest)
    raise IndexError("NEBO-RF166-G160-008", "unknown ProjectSymbolIndex command")


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except IndexError as error:
        print(f"{error.code}: {error.message}; note=no ProjectSymbolIndex state was published", file=sys.stderr)
        raise SystemExit(1)
    except (OSError, UnicodeError, ValueError, struct.error, subprocess.TimeoutExpired) as error:
        print(f"NEBO-RF166-G160-008: {error}; note=no ProjectSymbolIndex state was published", file=sys.stderr)
        raise SystemExit(1)
