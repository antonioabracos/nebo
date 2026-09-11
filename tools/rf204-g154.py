#!/usr/bin/python3
"""Bounded G154 CLI adapter over native module and .ni Assembly owners."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import stat
import struct
import subprocess
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
COMPILER = ROOT / "build" / "bin" / "neboc"
CODEC = ROOT / "build" / "tests" / "rf166" / "g154" / "interface_codec_probe"
G048 = ROOT / "tools" / "rf204-g048.py"
MAX_SOURCE_BYTES = 4096
MAX_INTERFACE_BYTES = 1 << 24
TARGET = "x86_64-systemv-elf-linux"
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1


class InterfaceError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def usage() -> int:
    print(
        "neboc: usage: emit-interface <module.no> --unit <file.no> --unit <file.no> "
        "-o <module.ni> [--cache-dir <dir>]; interface inspect <file.ni> [--json]; "
        "api-diff <old.ni> <new.ni>",
        file=sys.stderr,
    )
    return 2


def fnv(data: bytes, state: int = FNV_OFFSET) -> int:
    value = state
    for byte in data:
        value ^= byte
        value = (value * FNV_PRIME) & MASK64
    return value or 1


def digest_text(value: str) -> int:
    return fnv(value.encode("utf-8"))


def digest_qwords(values: list[int]) -> int:
    return fnv(b"".join(struct.pack("<Q", value & MASK64) for value in values))


def check_regular(path: Path, maximum: int, code: str) -> bytes:
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW)
    except OSError as exc:
        raise InterfaceError(code, f"cannot open {path}: {exc.strerror}") from exc
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode):
            raise InterfaceError(code, f"input must be a regular non-symlink file: {path}")
        if info.st_size > maximum:
            raise InterfaceError(code, f"input exceeds the {maximum}-byte budget: {path}")
        with os.fdopen(descriptor, "rb", closefd=False) as stream:
            data = stream.read(maximum + 1)
        if len(data) > maximum:
            raise InterfaceError(code, f"input exceeds the {maximum}-byte budget: {path}")
        return data
    finally:
        os.close(descriptor)


def native(arguments: list[str], payload: bytes | None = None) -> subprocess.CompletedProcess[bytes]:
    if not CODEC.is_file():
        raise InterfaceError("NEBO-RF166-G154-IO", f"native interface codec is unavailable: {CODEC}")
    return subprocess.run(
        [str(CODEC), *arguments],
        input=payload,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=15,
        check=False,
    )


def compiler(arguments: list[str]) -> subprocess.CompletedProcess[str]:
    if not COMPILER.is_file():
        raise InterfaceError("NEBO-RF166-G154-IO", f"native compiler is unavailable: {COMPILER}")
    return subprocess.run(
        [str(COMPILER), *arguments],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=15,
        check=False,
    )


def parse_info(output: str) -> dict[str, str]:
    facts: dict[str, str] = {}
    for line in output.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key in facts:
            raise InterfaceError("NEBO-RF166-G154-007", f"duplicate native fact: {key}")
        facts[key] = value
    required = {
        "module.id",
        "module.logical",
        "module.rank",
        "module.sourceRevision",
        "graph.snapshot",
        "graph.units",
        "module.imports",
        "module.startRefs",
        "module.visibility",
        "module.exportSymbolId",
        "module.exportValue",
    }
    if required - facts.keys():
        raise InterfaceError("NEBO-RF166-G154-007", "native module-info omitted required facts")
    return facts


def load_module(entry: Path, units: list[Path]) -> tuple[dict[str, str], list[dict[str, str]]]:
    paths = [entry, *units]
    if len(paths) != 3:
        raise InterfaceError("USAGE", "emit-interface requires exactly two --unit inputs")
    identities: set[tuple[int, int]] = set()
    for path in paths:
        check_regular(path, MAX_SOURCE_BYTES, "NEBO-RF166-G154-IO")
        info = path.stat()
        identity = (info.st_dev, info.st_ino)
        if identity in identities:
            raise InterfaceError("NEBO-RF166-G154-007", "module inputs must have distinct identities")
        identities.add(identity)
    common = [str(entry)]
    for unit in units:
        common.extend(("--unit", str(unit)))
    checked = compiler(["module-check", *common])
    if checked.returncode != 0:
        sys.stderr.write(checked.stderr)
        raise InterfaceError("NATIVE", "native module validation failed")
    graph_result = compiler(["module-graph", *common, "--format", "json"])
    if graph_result.returncode != 0:
        sys.stderr.write(graph_result.stderr)
        raise InterfaceError("NATIVE", "native module graph construction failed")
    try:
        graph = json.loads(graph_result.stdout)
    except (TypeError, ValueError) as exc:
        raise InterfaceError("NEBO-RF166-G154-007", "native module graph was not valid JSON") from exc
    infos: list[dict[str, str]] = []
    for position, selected in enumerate(paths):
        others = [path for index, path in enumerate(paths) if index != position]
        result = compiler(
            ["module-info", str(selected), "--unit", str(others[0]), "--unit", str(others[1])]
        )
        if result.returncode != 0:
            sys.stderr.write(result.stderr)
            raise InterfaceError("NATIVE", "native module-info construction failed")
        infos.append(parse_info(result.stdout))
    if {item["graph.snapshot"] for item in infos} != {str(graph.get("snapshot"))}:
        raise InterfaceError("NEBO-RF166-G154-007", "module graph changed during interface emission")
    return infos[0], sorted(infos[1:], key=lambda item: int(item["module.id"]))


def encode_request(root: dict[str, str], dependencies: list[dict[str, str]]) -> bytes:
    module_id = int(root["module.id"])
    target = digest_text(TARGET)
    symbol_id = int(root["module.exportSymbolId"])
    name_digest = symbol_id
    type_digest = digest_text("Int")
    layout_digest = digest_qwords([target, type_digest, 8, 8])
    value = int(root["module.exportValue"])
    constant_digest = digest_qwords([value & MASK64])
    visibility = int(root["module.visibility"])
    export = (
        symbol_id,
        name_digest,
        (3 | (visibility << 32)),        # constant kind, native visibility
        type_digest,
        0,
        layout_digest,
        constant_digest,
        6,                               # layout + constant payloads
    )
    dependency_ids = [int(item["module.id"]) for item in dependencies]
    public_dependency_surface = [
        value
        for item in dependencies
        if int(item["module.visibility"]) == 1
        for value in (
            int(item["module.id"]),
            int(item["module.exportSymbolId"]),
            int(item["module.exportValue"]),
        )
    ]
    dependency_id = digest_qwords(dependency_ids)
    dependency_api = digest_qwords([*dependency_ids, *public_dependency_surface])
    dependency_abi = digest_qwords([target, *dependency_ids, *public_dependency_surface])
    effects = 1 if int(root["module.startRefs"]) else 0
    capabilities = 1 if effects else 0
    doc_digest = digest_text(f"{root['module.logical']}:interface-documentation")
    metadata = (
        symbol_id,
        effects,
        capabilities,
        (1 | (3 << 32)),                 # owned + doc/dependency presence
        doc_digest,
        dependency_id,
        dependency_api,
        dependency_abi,
    )
    return struct.pack("<19Q", module_id, 1, target, *export, *metadata)


def native_emit(request: bytes) -> bytes:
    if len(request) != 152:
        raise InterfaceError("NEBO-RF166-G154-007", "invalid internal interface request")
    result = native(["--emit"], request)
    if result.returncode != 0 or not (64 <= len(result.stdout) <= MAX_INTERFACE_BYTES):
        raise InterfaceError("NEBO-RF166-G154-007", "native interface writer rejected the request")
    native_inspect(result.stdout, "native-writer-output")
    return result.stdout


def diagnostic_for_reason(reason: int) -> str:
    if reason in {3, 4, 5, 6, 7, 8}:
        return "NEBO-RF166-G154-001"
    if reason in {2, 9, 10, 11, 12, 13, 14, 15, 16, 17, 20}:
        return "NEBO-RF166-G154-003"
    if reason in {18, 19}:
        return "NEBO-RF166-G154-004"
    return "NEBO-RF166-G154-007"


def native_inspect(data: bytes, source: str) -> tuple[int, ...]:
    result = native(["--inspect"], data)
    if result.returncode != 0 or len(result.stdout) != 80:
        raise InterfaceError("NEBO-RF166-G154-IO", "native interface reader did not return a complete result")
    words = struct.unpack("<10Q", result.stdout)
    status, reason = words[:2]
    if status:
        code = diagnostic_for_reason(reason)
        raise InterfaceError(
            code,
            f"compiled interface rejected; primary={source}:byte=0..{min(len(data), 64)}; "
            f"reason={reason}; note=no interface state was published",
        )
    return words[2:]


def records_from_validated(data: bytes, summary: tuple[int, ...]) -> tuple[list[tuple[int, ...]], list[tuple[int, ...]]]:
    section_count = summary[0]
    exports: list[tuple[int, ...]] = []
    metadata: list[tuple[int, ...]] = []
    for index in range(section_count):
        kind, _flags, offset, length, _digest = struct.unpack_from("<IIQQQ", data, 64 + index * 32)
        records = [struct.unpack_from("<8Q", data, offset + item * 64) for item in range(length // 64)]
        if kind == 1:
            exports = records
        elif kind == 2:
            metadata = records
    return exports, metadata


def material_module_record(data: bytes) -> tuple[int, ...]:
    result = native(["--module"], data)
    if result.returncode or len(result.stdout) != 144:
        raise InterfaceError("NEBO-RF166-G154-IO", "native module interface decoder failed")
    words = struct.unpack("<18Q", result.stdout)
    if words[0]:
        raise InterfaceError("NEBO-RF166-G154-007", "typed module payload disagrees with the authenticated public interface")
    return words[2:]


def attach_module_value(data: bytes, root: dict[str, str]) -> bytes:
    # The existing source owner supplies these typed facts. This adapter only
    # transports them; native owners authenticate the resulting ModuleRecord.
    if int(root["module.visibility"]) != 1 or int(root["module.imports"]) or int(root["module.startRefs"]):
        return data
    logical = root["module.logical"].encode("ascii")
    if not 1 <= len(logical) <= 32:
        raise InterfaceError("NEBO-RF166-G154-007", "module name exceeds the current typed constant profile")
    payload = struct.pack("<8sQQQ32sQQ", b"NEBOMDC1", int(root["module.exportSymbolId"]),
                          int(root["module.exportValue"]), len(logical), logical, 0, 0)
    count = struct.unpack_from("<I", data, 48)[0]
    if count != 2:
        raise InterfaceError("NEBO-RF166-G154-007", "unexpected native base section directory")
    result = bytearray(data[:64])
    for index in range(count):
        kind, flags, offset, length, digest = struct.unpack_from("<IIQQQ", data, 64 + 32*index)
        result.extend(struct.pack("<IIQQQ", kind, flags, offset+32, length, digest))
    result.extend(struct.pack("<IIQQQ", 4, 1, len(data)+32, len(payload), fnv(payload)))
    result.extend(data[128:])
    result.extend(payload)
    struct.pack_into("<II", result, 48, 3, len(result))
    struct.pack_into("<Q", result, 56, fnv(result[64:], fnv(result[:56])))
    material_module_record(bytes(result))
    return bytes(result)


def behavior_fingerprint(metadata: list[tuple[int, ...]]) -> int:
    projection: list[int] = []
    for record in metadata:
        ownership_and_flags = record[3]
        projection.extend((record[0], record[1], record[2], ownership_and_flags, record[4], record[5]))
    return digest_qwords(projection or [1])


def api_surface(data: bytes, source: str) -> dict[int, tuple[int, ...]]:
    summary = native_inspect(data, source)
    exports, metadata = records_from_validated(data, summary)
    metadata_by_symbol = {record[0]: record for record in metadata}
    surface: dict[int, tuple[int, ...]] = {}
    for record in exports:
        semantic = metadata_by_symbol.get(record[0], (record[0], 0, 0, 1, 0, 0, 0, 0))
        surface[record[0]] = (
            record[1],
            record[2],
            record[3],
            record[4],
            record[6],
            record[7] & ~2,
            semantic[1],
            semantic[2],
            semantic[3] & ~(1 << 32),
            semantic[5],
            semantic[6],
        )
    return surface


def interface_report(data: bytes, source: str) -> dict[str, object]:
    summary = native_inspect(data, source)
    exports, metadata = records_from_validated(data, summary)
    metadata_by_symbol = {record[0]: record for record in metadata}
    material = None
    for index in range(summary[0]):
        if struct.unpack_from("<I", data, 64+32*index)[0] == 4:
            material = material_module_record(data)
    typed_projection: list[int] = []
    for record in exports:
        typed_projection.extend((record[0], record[3], record[6]))
    for record in metadata:
        typed_projection.extend((record[0], record[1], record[2], record[3] & 0xFFFFFFFF))
    return {
        "schema": 1,
        "edition": struct.unpack_from("<I", data, 12)[0],
        "target": TARGET if summary[5] == digest_text(TARGET) else f"0x{summary[5]:016x}",
        "targetDigest": f"0x{summary[5]:016x}",
        "moduleId": summary[2],
        "bytes": summary[1],
        "sections": summary[0],
        "exports": len(exports),
        "metadataRecords": len(metadata),
        "apiFingerprint": f"0x{summary[3]:016x}",
        "abiFingerprint": f"0x{summary[4]:016x}",
        "contentDigest": f"0x{summary[6]:016x}",
        "unknownOptionalSections": summary[7],
        "symbolIds": [record[0] for record in exports],
        "symbolRecords": [
            {
                "symbolId": record[0],
                "nameDigest": f"0x{record[1]:016x}",
                "kind": record[2] & 0xFFFF_FFFF,
                "visibility": record[2] >> 32,
                "typeDigest": f"0x{record[3]:016x}",
                "receiverTypeId": record[4],
                "layoutDigest": f"0x{record[5]:016x}",
                "constantDigest": f"0x{record[6]:016x}",
                "flags": record[7],
                "effects": metadata_by_symbol.get(record[0], (0, 0, 0, 0, 0, 0, 0, 0))[1],
                "capabilities": metadata_by_symbol.get(record[0], (0, 0, 0, 0, 0, 0, 0, 0))[2],
                "ownership": metadata_by_symbol.get(record[0], (0, 0, 0, 1, 0, 0, 0, 0))[3] & 0xFFFF_FFFF,
                "docDigest": f"0x{metadata_by_symbol.get(record[0], (0, 0, 0, 0, 0, 0, 0, 0))[4]:016x}",
            }
            for record in exports
        ],
        "constantDigests": [f"0x{record[6]:016x}" for record in exports],
        "materialModuleValue": None if material is None else material[6],
        "effects": [record[1] for record in metadata],
        "capabilities": [record[2] for record in metadata],
        "ownership": [record[3] & 0xFFFFFFFF for record in metadata],
        "dependencyIds": [record[5] for record in metadata],
        "behaviorFingerprint": f"0x{behavior_fingerprint(metadata):016x}",
        "typedHirDigest": f"0x{digest_qwords(typed_projection or [1]):016x}",
    }


def atomic_write(path: Path, data: bytes) -> None:
    parent = path.parent
    if not parent.is_dir() or parent.is_symlink():
        raise InterfaceError("NEBO-RF166-G154-IO", f"output parent must be a real directory: {parent}")
    if path.exists() and (path.is_symlink() or not path.is_file()):
        raise InterfaceError("NEBO-RF166-G154-IO", f"output must be a regular file: {path}")
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=parent)
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


def cache_key(root: dict[str, str], dependencies: list[dict[str, str]]) -> tuple[int, ...]:
    source_digest = digest_qwords([int(root["module.sourceRevision"]), *[int(item["module.sourceRevision"]) for item in dependencies]])
    dependency_digest = digest_qwords(
        [value for item in dependencies for value in (int(item["module.id"]), int(item["module.sourceRevision"]))]
    )
    return (
        int(root["module.id"]),
        fnv(check_regular(COMPILER, MAX_INTERFACE_BYTES, "NEBO-RF166-G154-IO")),
        1,
        digest_text(TARGET),
        source_digest,
        dependency_digest,
        digest_text("std.prelude:edition-1"),
    )


def native_cache_lookup(key: tuple[int, ...], entry: bytes) -> tuple[int, int, int, int]:
    if len(key) != 7 or len(entry) != 72:
        raise InterfaceError("NEBO-RF166-G154-007", "invalid cache probe request")
    result = native(["--cache"], struct.pack("<7Q", *key) + entry)
    if result.returncode != 0 or len(result.stdout) != 48:
        raise InterfaceError("NEBO-RF166-G154-IO", "native cache owner did not return a complete result")
    status, reason, state, artifact, invalidation, checksum = struct.unpack("<6Q", result.stdout)
    if status:
        raise InterfaceError(
            "NEBO-RF166-G154-005",
            f"interface cache entry rejected; reason={reason}; note=corrupt cache is never reused",
        )
    return state, artifact, invalidation, checksum


def emit_interface(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc emit-interface")
    parser.add_argument("module")
    parser.add_argument("--unit", action="append", default=[])
    parser.add_argument("-o", "--output", required=True)
    parser.add_argument("--cache-dir")
    args = parser.parse_args(arguments)
    entry = Path(args.module)
    units = [Path(value) for value in args.unit]
    output = Path(args.output)
    if output.suffix != ".ni":
        raise InterfaceError("NEBO-RF166-G154-001", "compiled interface output must use the canonical .ni extension")
    root, dependencies = load_module(entry, units)
    key = cache_key(root, dependencies)
    cache_state = "DISABLED"
    data: bytes | None = None
    cache_artifact: Path | None = None
    cache_entry: Path | None = None
    if args.cache_dir:
        directory = Path(args.cache_dir)
        if directory.exists() and (directory.is_symlink() or not directory.is_dir()):
            raise InterfaceError("NEBO-RF166-G154-IO", "cache path must be a real directory")
        directory.mkdir(parents=True, exist_ok=True)
        stem = f"{key[0]:016x}"
        cache_artifact = directory / f"{stem}.ni"
        cache_entry = directory / f"{stem}.key"
        if cache_artifact.exists() and cache_entry.exists():
            raw_entry = check_regular(cache_entry, 72, "NEBO-RF166-G154-005")
            if len(raw_entry) != 72:
                raise InterfaceError("NEBO-RF166-G154-005", "cache key record has an invalid size")
            state, artifact, _mask, _checksum = native_cache_lookup(key, raw_entry)
            if state == 1:
                candidate = check_regular(cache_artifact, MAX_INTERFACE_BYTES, "NEBO-RF166-G154-005")
                report = interface_report(candidate, str(cache_artifact))
                if int(str(report["contentDigest"]), 16) != artifact:
                    raise InterfaceError("NEBO-RF166-G154-005", "cache artifact digest does not match its authenticated entry")
                if (
                    report["moduleId"] != key[0]
                    or report["edition"] != key[2]
                    or int(str(report["targetDigest"]), 16) != key[3]
                ):
                    raise InterfaceError("NEBO-RF166-G154-005", "cache artifact identity does not match the complete key")
                data = candidate
                cache_state = "HIT"
            else:
                cache_state = "STALE_MISS"
        else:
            cache_state = "MISS"
    if data is None:
        data = attach_module_value(native_emit(encode_request(root, dependencies)), root)
    report = interface_report(data, str(output))
    atomic_write(output, data)
    if cache_artifact is not None and cache_entry is not None and cache_state != "HIT":
        artifact_digest = int(str(report["contentDigest"]), 16)
        authenticated = struct.pack("<8Q", *key, artifact_digest)
        entry = authenticated + struct.pack("<Q", fnv(authenticated))
        atomic_write(cache_artifact, data)
        atomic_write(cache_entry, entry)
    print(json.dumps({"command": "emit-interface", "cache": cache_state, **report}, sort_keys=True, separators=(",", ":")))
    return 0


def inspect_interface(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc interface inspect")
    parser.add_argument("path")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(arguments)
    path = Path(args.path)
    data = check_regular(path, MAX_INTERFACE_BYTES, "NEBO-RF166-G154-IO")
    report = {"command": "interface-inspect", "path": str(path), **interface_report(data, str(path))}
    if args.json:
        print(json.dumps(report, sort_keys=True, separators=(",", ":")))
    else:
        for key in sorted(report):
            print(f"{key}={report[key]}")
    return 0


def native_compatibility(old: dict[str, object], new: dict[str, object], flags: int) -> tuple[int, ...]:
    request = struct.pack(
        "<9Q",
        int(str(old["apiFingerprint"]), 16),
        int(str(new["apiFingerprint"]), 16),
        int(str(old["abiFingerprint"]), 16),
        int(str(new["abiFingerprint"]), 16),
        int(str(old["behaviorFingerprint"]), 16),
        int(str(new["behaviorFingerprint"]), 16),
        int(str(old["targetDigest"]), 16),
        int(str(new["targetDigest"]), 16),
        flags,
    )
    result = native(["--compat"], request)
    if result.returncode != 0 or len(result.stdout) != 56:
        raise InterfaceError("NEBO-RF166-G154-IO", "native compatibility owner did not return a complete result")
    words = struct.unpack("<7Q", result.stdout)
    if words[0]:
        code = "NEBO-RF166-G154-006" if words[1] == 3 else "NEBO-RF166-G154-007"
        raise InterfaceError(code, f"interfaces cannot be compared; reason={words[1]}")
    return words[2:]


def api_diff(arguments: list[str]) -> int:
    if len(arguments) == 2 and all(Path(value).suffix == ".ni" for value in arguments):
        old_path, new_path = map(Path, arguments)
        old_data = check_regular(old_path, MAX_INTERFACE_BYTES, "NEBO-RF166-G154-IO")
        new_data = check_regular(new_path, MAX_INTERFACE_BYTES, "NEBO-RF166-G154-IO")
        old = interface_report(old_data, str(old_path))
        new = interface_report(new_data, str(new_path))
        old_symbols = set(old["symbolIds"])
        new_symbols = set(new["symbolIds"])
        api_changed = old["apiFingerprint"] != new["apiFingerprint"]
        abi_changed = old["abiFingerprint"] != new["abiFingerprint"]
        behavior_changed = old["behaviorFingerprint"] != new["behaviorFingerprint"]
        old_surface = api_surface(old_data, str(old_path))
        new_surface = api_surface(new_data, str(new_path))
        additive = old_symbols < new_symbols and all(
            new_surface.get(symbol) == old_surface[symbol] for symbol in old_symbols
        )
        flags = 1 if api_changed and additive else 0
        if not api_changed and not abi_changed and behavior_changed:
            flags |= 2
        native_result = native_compatibility(old, new, flags)
        names = {1: "identical", 2: "source-compatible", 3: "recompile-required", 4: "breaking"}
        report = {
            "command": "api-diff",
            "classification": names[native_result[0]],
            "apiChanged": bool(native_result[1]),
            "abiChanged": bool(native_result[2]),
            "behaviorChanged": bool(native_result[3]),
            "proofFlags": native_result[4],
            "oldApiFingerprint": old["apiFingerprint"],
            "newApiFingerprint": new["apiFingerprint"],
            "oldAbiFingerprint": old["abiFingerprint"],
            "newAbiFingerprint": new["abiFingerprint"],
        }
        print(json.dumps(report, sort_keys=True, separators=(",", ":")))
        return 1 if native_result[0] == 4 else 0
    fallback = subprocess.run(
        ["/usr/bin/python3", str(G048), "api-diff", *arguments],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=15,
        check=False,
    )
    sys.stdout.buffer.write(fallback.stdout)
    sys.stderr.buffer.write(fallback.stderr)
    return fallback.returncode


def main(arguments: list[str]) -> int:
    if not arguments:
        return usage()
    if arguments[0] == "emit-interface":
        return emit_interface(arguments[1:])
    if arguments[:2] == ["interface", "inspect"]:
        return inspect_interface(arguments[2:])
    if arguments[0] == "api-diff":
        return api_diff(arguments[1:])
    return usage()


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except InterfaceError as exc:
        if exc.code == "USAGE":
            raise SystemExit(usage())
        if exc.code == "NATIVE":
            raise SystemExit(1)
        print(f"{exc.code}: {exc.message}", file=sys.stderr)
        raise SystemExit(1)
    except (OSError, ValueError, struct.error, subprocess.TimeoutExpired) as exc:
        print(f"NEBO-RF166-G154-IO: {exc}", file=sys.stderr)
        raise SystemExit(3)
