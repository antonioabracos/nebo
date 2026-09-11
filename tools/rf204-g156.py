#!/usr/bin/env python3
"""G156 DocRecord materializer over the canonical native G155 Doc AST."""

from __future__ import annotations

import json
import os
from pathlib import Path
import stat
import struct
import subprocess
import sys


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
COMPILER = ROOT / "build" / "bin" / "neboc"
NATIVE = ROOT / "build" / "bin" / "nebo-doc-record"
MAX_SOURCE_BYTES = 16_384
RECORD_BYTES = 4096
TEXT_OFFSET = 256
TEXT_CAPACITY = 3832
INTERFACE_BYTES = 4192
FIELDS = (
    "title", "summary", "parameters", "returns", "errors", "effects",
    "capabilities", "ownership", "complexity", "risks", "since",
    "deprecated", "example", "law",
)
SIGNATURE_FIELDS = {
    "parameters", "returns", "errors", "effects", "capabilities", "ownership",
}
SLOTS = {
    "title": 8, "summary": 9, "returns": 10, "ownership": 11,
    "complexity": 12, "since": 13, "deprecated": 14,
    "parameters": 18, "errors": 22, "effects": 23, "capabilities": 24,
    "risks": 25, "example": 26, "law": 27,
}


class DocRecordError(Exception):
    pass


def fnv(data: bytes) -> int:
    value = 0xCBF29CE484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001B3) & 0xFFFF_FFFF_FFFF_FFFF
    return value or 1


def read_source(raw: str) -> tuple[Path, bytes]:
    path = Path(raw).absolute()
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK)
    except OSError as error:
        raise DocRecordError(f"cannot open source: {error.strerror}") from error
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_SOURCE_BYTES:
            raise DocRecordError("source must be a bounded regular non-symlink file")
        data = b""
        while len(data) <= MAX_SOURCE_BYTES:
            chunk = os.read(descriptor, min(4096, MAX_SOURCE_BYTES + 1 - len(data)))
            if not chunk:
                break
            data += chunk
        if len(data) > MAX_SOURCE_BYTES:
            raise DocRecordError("source exceeds the bounded documentation profile")
        data.decode("utf-8", "strict")
        return path, data
    finally:
        os.close(descriptor)


def canonical_ast(path: Path) -> dict[str, object]:
    result = subprocess.run(
        [str(COMPILER), "dump", "doc-ast", str(path)],
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        timeout=20, check=False, env={},
    )
    if result.returncode != 0:
        sys.stderr.buffer.write(result.stderr)
        raise DocRecordError("canonical DocParser rejected the symbol")
    try:
        value = json.loads(result.stdout)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise DocRecordError("canonical DocParser returned invalid transport") from error
    if value.get("parserAuthority") != "native:compiler/parser/doc_lexer.asm":
        raise DocRecordError("DocRecord requires the canonical native parser authority")
    return value


def payloads(ast: dict[str, object], source: bytes) -> dict[str, str]:
    result: dict[str, str] = {}
    for node in ast["fieldNodes"]:
        kind = node["kind"]
        offset, length = node["payload"]["span"]
        if kind not in FIELDS or offset < 0 or length < 0 or offset + length > len(source):
            raise DocRecordError("Doc AST published an invalid field span")
        result[kind] = source[offset:offset + length].decode("utf-8", "strict")
    if "title" not in result:
        raise DocRecordError("DocRecord requires a title")
    return result


def semantic_entries(value: str) -> list[bytes]:
    # This binds already parsed schema payloads; it is not a second source/doc parser.
    entries = [item.strip().encode("utf-8") for item in value.split(";") if item.strip()]
    return entries or [value.strip().encode("utf-8")]


def native(mode: str, payload: bytes, expected: int) -> bytes:
    result = subprocess.run(
        [str(NATIVE), mode], input=payload, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=10, check=False, env={},
    )
    if result.returncode or len(result.stdout) != expected or result.stderr:
        raise DocRecordError(f"native DocRecord {mode[2:]} rejected the semantic record")
    return result.stdout


def build_record(ast: dict[str, object], source: bytes) -> tuple[bytes, dict[str, str]]:
    texts = payloads(ast, source)
    text_bytes = json.dumps(texts, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    if len(text_bytes) > TEXT_CAPACITY:
        raise DocRecordError("canonical documentation text exceeds DocRecordV1 capacity")
    attachment = ast["attachment"]
    start, length = ast["span"]
    signature_material = bytearray(str(attachment["kind"]).encode("utf-8"))
    for name in FIELDS:
        if name in SIGNATURE_FIELDS and name in texts:
            signature_material.extend(struct.pack("<H", FIELDS.index(name) + 1))
            signature_material.extend(texts[name].encode("utf-8"))

    words = [0] * (RECORD_BYTES // 8)
    words[2] = int(attachment["symbolId"])
    words[3] = int(start)
    words[4] = int(start) + int(length)
    words[5] = fnv(bytes(signature_material))
    words[6] = int(ast["fieldMask"])
    words[7] = (1 << 32) | 4  # PUBLIC | SOURCE
    words[15] = int(str(ast["astDigest"]), 16)
    counts = {name: len(semantic_entries(texts[name])) if name in texts else 0 for name in FIELDS}
    counts["example"] = int(ast["examples"])
    counts["law"] = int(ast["laws"])
    if counts["parameters"] > 4:
        raise DocRecordError("DocRecordV1 supports at most four parameter identities")
    words[16] = counts["parameters"] | (counts["errors"] << 8) | (counts["effects"] << 16) | (counts["capabilities"] << 24)
    words[17] = counts["risks"] | (counts["example"] << 8) | (counts["law"] << 16)
    for name, slot in SLOTS.items():
        if name in texts:
            words[slot] = fnv(texts[name].encode("utf-8"))
    if "parameters" in texts:
        for index, value in enumerate(semantic_entries(texts["parameters"])):
            words[18 + index] = fnv(value)
    if "returns" in texts:
        words[28] = fnv(semantic_entries(texts["returns"])[0])
    words[29] = len(text_bytes)
    request = bytearray(struct.pack(f"<{len(words)}Q", *words))
    request[TEXT_OFFSET:TEXT_OFFSET + len(text_bytes)] = text_bytes
    record = native("--build", bytes(request), RECORD_BYTES)
    return record, texts


def decode(record: bytes, ast: dict[str, object], texts: dict[str, str]) -> dict[str, object]:
    words = struct.unpack(f"<{RECORD_BYTES // 8}Q", record)
    identities = {
        "parameters": [f"0x{value:016x}" for value in words[18:22] if value],
        "return": f"0x{words[28]:016x}" if words[28] else None,
        "errors": f"0x{words[22]:016x}" if words[22] else None,
        "effects": f"0x{words[23]:016x}" if words[23] else None,
        "capabilities": f"0x{words[24]:016x}" if words[24] else None,
    }
    return {
        "schema": 1,
        "node": "DocRecord",
        "attachment": ast["attachment"],
        "symbolId": words[2],
        "sourceSpan": [words[3], words[4] - words[3]],
        "signatureHash": f"0x{words[5]:016x}",
        "contentHash": f"0x{words[-1]:016x}",
        "fieldMask": words[6],
        "origin": "SOURCE",
        "visibility": "PUBLIC",
        "text": texts,
        "identities": identities,
        "projectIndex": {"key": f"0x{words[30]:016x}", "lookup": "SymbolId"},
        "interface": {
            "schema": 1, "sectionKind": 3, "optional": True,
            "bytes": INTERFACE_BYTES, "roundTrip": "BYTE_IDENTICAL",
        },
        "owners": {
            "parser": "compiler/parser/doc_lexer.asm",
            "semantic": "compiler/semantic/docs/doc_record.asm",
            "interface": "compiler/interface/doc_serialization.asm",
        },
    }


def main(arguments: list[str]) -> int:
    if len(arguments) != 3 or arguments[:2] != ["dump", "doc-record"]:
        print("neboc: usage: dump doc-record <symbol>", file=sys.stderr)
        return 2
    path, source = read_source(arguments[2])
    ast = canonical_ast(path)
    record, texts = build_record(ast, source)
    interface = native("--serialize", record, INTERFACE_BYTES)
    roundtrip = native("--deserialize", interface, RECORD_BYTES)
    if roundtrip != record:
        raise DocRecordError("DocRecord native interface round-trip diverged")
    print(json.dumps(decode(record, ast, texts), sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (DocRecordError, OSError, UnicodeError, subprocess.TimeoutExpired) as error:
        print(f"NEBO-RF166-G156-001: {error}; note=no DocRecord was published", file=sys.stderr)
        raise SystemExit(1)
