#!/usr/bin/python3
"""Bounded G155 renderer over the canonical native DocParser.parse owner."""

from __future__ import annotations

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
PARSER = ROOT / "build" / "bin" / "nebo-doc-parser"
COMPILER = ROOT / "build" / "bin" / "neboc"
MAX_SOURCE_BYTES = 16_384
RESULT = struct.Struct("<72Q")
ERROR = struct.Struct("<2Q")
FIELD_RECORD_QWORDS = 4

ATTACHMENTS = {
    1: "module",
    2: "type",
    3: "struct",
    4: "enum",
    5: "function",
    6: "constant",
}
FIELDS = (
    "title",
    "summary",
    "parameters",
    "returns",
    "errors",
    "effects",
    "capabilities",
    "ownership",
    "complexity",
    "risks",
    "since",
    "deprecated",
    "example",
    "law",
)
DIAGNOSTICS = {
    1: ("NEBO-RF166-G155-IO", "invalid DocParser transport argument"),
    2: ("NEBO-RF166-G155-001", "semantic documentation source is empty"),
    3: ("NEBO-RF166-G155-002", "semantic documentation source is not valid UTF-8"),
    4: ("NEBO-RF166-G155-001", "expected the singular `doc` keyword"),
    5: ("NEBO-RF166-G155-001", "malformed semantic documentation grammar"),
    6: ("NEBO-RF166-G155-003", "unknown field in the stable doc schema"),
    7: ("NEBO-RF166-G155-004", "duplicate field in one doc block"),
    8: ("NEBO-RF166-G155-005", "doc block has no immediately attached declaration"),
    9: ("NEBO-RF166-G155-006", "a declaration cannot have two attached doc blocks"),
    10: ("NEBO-RF166-G155-007", "malformed example or law code block"),
    11: ("NEBO-RF166-G155-008", "semantic documentation exceeds its bounded profile"),
}


class DocError(Exception):
    def __init__(self, reason: int, message: str | None = None, span: int = 0):
        super().__init__(message)
        self.reason = reason
        self.message = message
        self.span = span


def usage() -> int:
    print("neboc: usage: dump doc-ast <source>", file=sys.stderr)
    return 2


def read_source(raw: str) -> tuple[Path, bytes]:
    path = Path(raw).absolute()
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK)
    except OSError as exc:
        raise DocError(1, f"cannot open {path}: {exc.strerror}") from exc
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode):
            raise DocError(1, f"source must be a regular non-symlink file: {path}")
        if info.st_size > MAX_SOURCE_BYTES:
            raise DocError(11, f"source exceeds {MAX_SOURCE_BYTES} bytes")
        data = b""
        while len(data) <= MAX_SOURCE_BYTES:
            chunk = os.read(descriptor, min(4096, MAX_SOURCE_BYTES + 1 - len(data)))
            if not chunk:
                break
            data += chunk
        if len(data) > MAX_SOURCE_BYTES:
            raise DocError(11, f"source exceeds {MAX_SOURCE_BYTES} bytes")
        return path, data
    finally:
        os.close(descriptor)


def native_parse(data: bytes) -> tuple[int, ...]:
    if not PARSER.is_file():
        raise DocError(1, f"native DocParser probe is unavailable: {PARSER}")
    try:
        result = subprocess.run(
            [str(PARSER)],
            input=data,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
            check=False,
            env={},
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise DocError(1, f"native DocParser transport failed: {exc}") from exc
    if result.returncode == 0 and len(result.stdout) == RESULT.size and not result.stderr:
        return RESULT.unpack(result.stdout)
    if result.returncode == 1 and not result.stdout and len(result.stderr) == ERROR.size:
        reason, span = ERROR.unpack(result.stderr)
        raise DocError(int(reason), span=int(span))
    raise DocError(1, "native DocParser returned an invalid transport record")


def unpack_span(value: int) -> tuple[int, int]:
    return value & 0xFFFF_FFFF, value >> 32


def decode_span(data: bytes, packed_span: int, role: str, *, allow_empty: bool = False) -> tuple[int, int]:
    offset, length = unpack_span(packed_span)
    if (not allow_empty and not length) or offset + length > len(data):
        raise DocError(1, f"native {role} span is outside the source", packed_span)
    return offset, length


def compile_embedded(
    path: Path,
    data: bytes,
    kind: str,
    packed_span: int,
    packed_label_span: int,
) -> dict[str, object] | None:
    if not packed_span:
        return None
    offset, length = decode_span(data, packed_span, kind)
    label_offset, label_length = decode_span(data, packed_label_span, f"{kind} label")
    try:
        label = data[label_offset:label_offset + label_length].decode("utf-8", "strict")
    except UnicodeDecodeError as exc:
        raise DocError(3, f"{kind} label is not valid UTF-8", packed_label_span) from exc
    snippet = data[offset:offset + length]
    with tempfile.TemporaryDirectory(prefix=f"nebo-g155-{kind}-") as directory:
        source = Path(directory) / f"{kind}.no"
        source.write_bytes(snippet)
        try:
            checked = subprocess.run(
                [str(COMPILER), "check", str(source)],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=15,
                check=False,
                env={},
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise DocError(10, f"canonical Nebo parser could not check {kind}: {exc}", packed_span) from exc
        if checked.returncode != 0:
            detail = checked.stderr.decode("utf-8", "replace").splitlines()
            note = detail[0] if detail else "canonical Nebo parser rejected the embedded source"
            raise DocError(10, f"{kind} is not compilable Nebo code; related={note}", packed_span)
    return {
        "node": "DocExampleAst" if kind == "example" else "DocLawAst",
        "kind": kind,
        "name": label,
        "nameSpan": [label_offset, label_length],
        "span": [offset, length],
        "compilerAdmission": "PASS",
    }


def render(path: Path, data: bytes, words: tuple[int, ...]) -> dict[str, object]:
    header = words[:16]
    records = words[16:]
    (
        consumed,
        start,
        end,
        attachment_kind,
        attachment_span,
        field_mask,
        field_count,
        example_count,
        law_count,
        comments,
        cst_digest,
        ast_digest,
        symbol_id,
        example_span,
        law_span,
        flags,
    ) = header
    name_offset, name_length = decode_span(data, attachment_span, "attachment name")
    if start > end or end > len(data) or consumed > len(data):
        raise DocError(1, "native DocParser published an out-of-range result")
    try:
        attachment_name = data[name_offset:name_offset + name_length].decode("utf-8", "strict")
    except UnicodeDecodeError as exc:
        raise DocError(3, "attachment identity is not valid UTF-8", attachment_span) from exc
    if field_count > len(FIELDS) or example_count not in (0, 1) or law_count not in (0, 1):
        raise DocError(1, "native DocParser field cardinality is inconsistent")
    field_nodes: list[dict[str, object]] = []
    previous_end = start
    example_record: tuple[int, int] = (0, 0)
    law_record: tuple[int, int] = (0, 0)
    for ordinal in range(field_count):
        begin = ordinal * FIELD_RECORD_QWORDS
        kind_id, node_span, payload_span, label_span = records[begin:begin + FIELD_RECORD_QWORDS]
        if kind_id < 1 or kind_id > len(FIELDS):
            raise DocError(1, "native DocParser published an invalid field kind")
        node_offset, node_length = decode_span(data, node_span, "field")
        payload_offset, payload_length = decode_span(data, payload_span, "field payload", allow_empty=True)
        if node_offset < previous_end or payload_offset < node_offset or payload_offset + payload_length > node_offset + node_length:
            raise DocError(1, "native DocParser published inconsistent field source order")
        previous_end = node_offset + node_length
        kind = FIELDS[kind_id - 1]
        expected_payload_kind = "text" if kind in {"title", "summary", "since", "deprecated"} else "code" if kind in {"example", "law"} else "schema"
        node: dict[str, object] = {
            "node": "DocFieldAst",
            "kind": kind,
            "ordinal": ordinal,
            "span": [node_offset, node_length],
            "payload": {"kind": expected_payload_kind, "span": [payload_offset, payload_length]},
        }
        if kind in {"example", "law"}:
            label_offset, label_length = decode_span(data, label_span, f"{kind} label")
            node["labelSpan"] = [label_offset, label_length]
            if kind == "example":
                example_record = payload_span, label_span
            else:
                law_record = payload_span, label_span
        elif label_span:
            raise DocError(1, "native non-code field unexpectedly published a label")
        field_nodes.append(node)
    selected = [node["kind"] for node in field_nodes]
    expected_mask = sum(1 << (FIELDS.index(str(name))) for name in selected)
    if expected_mask != field_mask or len(selected) != field_count:
        raise DocError(1, "native DocParser field mask disagrees with field records")
    if example_record[0] != example_span or law_record[0] != law_span:
        raise DocError(1, "native embedded spans disagree with field records")
    embedded = [
        item
        for item in (
            compile_embedded(path, data, "example", *example_record),
            compile_embedded(path, data, "law", *law_record),
        )
        if item is not None
    ]
    return {
        "schema": 1,
        "node": "DocBlockAst",
        "source": str(path),
        "span": [start, end - start],
        "consumed": consumed,
        "attachment": {
            "kind": ATTACHMENTS.get(attachment_kind, "invalid"),
            "name": attachment_name,
            "nameSpan": [name_offset, name_length],
            "symbolId": symbol_id,
        },
        "fields": selected,
        "fieldNodes": field_nodes,
        "fieldMask": field_mask,
        "fieldCount": field_count,
        "examples": example_count,
        "laws": law_count,
        "embeddedCode": embedded,
        "trivia": {"comments": comments, "preservedInCst": bool(flags & 2)},
        "cstDigest": f"0x{cst_digest:016x}",
        "astDigest": f"0x{ast_digest:016x}",
        "parserAuthority": "native:compiler/parser/doc_lexer.asm",
        "effectsExecuted": False,
    }


def report_error(path: Path | None, error: DocError, data: bytes | None = None) -> None:
    code, default = DIAGNOSTICS.get(error.reason, DIAGNOSTICS[1])
    offset, length = unpack_span(error.span)
    location = str(path) if path is not None else "<source>"
    message = error.message or default
    extras = [f"primary={location}:byte={offset}..{offset + max(length, 1)}"]
    selected = data[offset:offset + length] if data is not None else b""
    if error.reason == 4 and selected == b"docs":
        extras.extend(("note=`doc` is a reserved singular keyword", f"fix=replace:{offset}:{offset + length}:doc"))
    elif error.reason == 4:
        extras.append("note=comments and ordinary declarations do not create DocBlockAst nodes")
    elif error.reason in {5, 6, 7, 8, 9, 10}:
        extras.append("note=no DocBlockAst or executable artifact was published")
    print(f"{code}: {message}; {'; '.join(extras)}", file=sys.stderr)


def main(arguments: list[str]) -> int:
    if len(arguments) != 3 or arguments[:2] != ["dump", "doc-ast"]:
        return usage()
    path: Path | None = None
    data: bytes | None = None
    try:
        path, data = read_source(arguments[2])
        words = native_parse(data)
        payload = render(path, data, words)
        print(json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
        return 0
    except DocError as error:
        report_error(path, error, data)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
