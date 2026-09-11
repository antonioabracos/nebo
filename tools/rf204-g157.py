#!/usr/bin/env python3
"""G157 semantic documentation checker over native DocRecord/DocValidator owners."""

from __future__ import annotations

import argparse
import hashlib
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
VALIDATOR = ROOT / "build" / "bin" / "nebo-doc-validator"
MAX_SOURCE_BYTES = 16_384
REQUEST = struct.Struct("<40Q")
ISSUE = struct.Struct("<8Q")
REPORT_BYTES = 7 * ISSUE.size
MAGIC = 0x37353156434F444E
FIELDS = (
    "title", "summary", "parameters", "returns", "errors", "effects",
    "capabilities", "ownership", "complexity", "risks", "since",
    "deprecated", "example", "law",
)
ISSUE_CODES = {
    1: ("NEBO-RF166-G157-001", "required documentation field is missing"),
    2: ("NEBO-RF166-G157-002", "documented parameter cardinality differs from the declaration"),
    3: ("NEBO-RF166-G157-003", "documented parameter identity, type, default, or order is stale"),
    4: ("NEBO-RF166-G157-004", "documented return contract differs from the resolved return"),
    5: ("NEBO-RF166-G157-005", "a possible typed error is undocumented"),
    6: ("NEBO-RF166-G157-006", "documentation declares an impossible typed error"),
    7: ("NEBO-RF166-G157-007", "documented effects contradict the resolved effect set"),
    8: ("NEBO-RF166-G157-008", "documented capabilities differ from resolved requirements"),
    9: ("NEBO-RF166-G157-009", "documented ownership differs from the resolved contract"),
    10: ("NEBO-RF166-G157-010", "documented complexity contradicts a known bound"),
    11: ("NEBO-RF166-G157-011", "a policy-required risk is undocumented"),
    12: ("NEBO-RF166-G157-012", "since/deprecated lifecycle metadata is inconsistent"),
    13: ("NEBO-RF166-G157-013", "documented target availability excludes the active target"),
    14: ("NEBO-RF166-G157-014", "documentation signature is stale"),
    15: ("NEBO-RF166-G157-015", "public symbol has no semantic documentation"),
}


class ValidationError(Exception):
    pass


def fnv(value: bytes) -> int:
    result = 0xCBF29CE484222325
    for byte in value:
        result = ((result ^ byte) * 0x100000001B3) & 0xFFFF_FFFF_FFFF_FFFF
    return result or 1


def packed_span(offset: int, length: int) -> int:
    return (length << 32) | offset


def unpack_span(value: int) -> list[int]:
    return [value & 0xFFFF_FFFF, value >> 32]


def read_source(raw: str) -> tuple[Path, bytes, tuple[int, int]]:
    path = Path(raw).absolute()
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK)
    except OSError as error:
        raise ValidationError(f"cannot open {path}: {error.strerror}") from error
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_SOURCE_BYTES:
            raise ValidationError("source must be a bounded regular non-symlink file")
        data = b""
        while len(data) <= MAX_SOURCE_BYTES:
            chunk = os.read(descriptor, min(4096, MAX_SOURCE_BYTES + 1 - len(data)))
            if not chunk:
                break
            data += chunk
        if len(data) > MAX_SOURCE_BYTES:
            raise ValidationError("source exceeds the G157 bounded profile")
        data.decode("utf-8", "strict")
        return path, data, (info.st_dev, info.st_ino)
    finally:
        os.close(descriptor)


def run_compiler(arguments: list[str]) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        [str(COMPILER), *arguments], stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20,
        check=False, env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
    )


def doc_record(path: Path, data: bytes) -> dict[str, object] | None:
    result = run_compiler(["dump", "doc-record", str(path)])
    if result.returncode:
        # A source with no leading doc block is a lint issue. A malformed doc
        # block remains a parser error and must not be reclassified.
        if not data.lstrip().startswith(b"doc"):
            return None
        ast_result = run_compiler(["dump", "doc-ast", str(path)])
        if ast_result.returncode:
            sys.stderr.buffer.write(result.stderr)
            raise ValidationError("canonical DocRecord construction failed")
        try:
            ast = json.loads(ast_result.stdout)
            texts: dict[str, str] = {}
            for node in ast["fieldNodes"]:
                offset, length = node["payload"]["span"]
                texts[str(node["kind"])] = data[offset:offset + length].decode("utf-8", "strict")
            return {
                "attachment": ast["attachment"], "fieldMask": ast["fieldMask"],
                "sourceSpan": ast["span"], "symbolId": ast["attachment"]["symbolId"],
                "text": texts,
                "owners": {"parser": "compiler/parser/doc_lexer.asm", "semantic": "compiler/semantic/docs/doc_record.asm"},
            }
        except (KeyError, TypeError, UnicodeDecodeError, json.JSONDecodeError) as error:
            raise ValidationError("canonical incomplete DocRecord transport is invalid") from error
    try:
        value = json.loads(result.stdout)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValidationError("canonical DocRecord transport is invalid") from error
    owners = value.get("owners", {})
    if owners.get("parser") != "compiler/parser/doc_lexer.asm" or owners.get("semantic") != "compiler/semantic/docs/doc_record.asm":
        raise ValidationError("untrusted DocRecord authority")
    return value


def skip_space(text: str, index: int) -> int:
    while index < len(text) and text[index].isspace():
        index += 1
    return index


def split_entries(payload: str) -> list[str]:
    values: list[str] = []
    start = 0
    quoted = False
    escaped = False
    depth = 0
    for index, char in enumerate(payload):
        if escaped:
            escaped = False
        elif char == "\\" and quoted:
            escaped = True
        elif char == '"':
            quoted = not quoted
        elif not quoted and char in "<([{":
            depth += 1
        elif not quoted and char in ">)]}":
            depth = max(0, depth - 1)
        elif not quoted and depth == 0 and char == ";":
            item = payload[start:index].strip()
            if item:
                values.append(item)
            start = index + 1
    tail = payload[start:].strip()
    if tail:
        values.append(tail)
    return values


def entry_pair(item: str) -> tuple[str, str]:
    quoted = False
    depth = 0
    for index, char in enumerate(item):
        if char == '"':
            quoted = not quoted
        elif not quoted and char in "<([{":
            depth += 1
        elif not quoted and char in ">)]}":
            depth = max(0, depth - 1)
        elif not quoted and depth == 0 and char == ":":
            key = item[:index].strip()
            value = item[index + 1:].strip()
            if len(value) >= 2 and value[0] == value[-1] == '"':
                value = value[1:-1]
            return key, value
    return item.strip(), ""


def normalized(value: str) -> str:
    return "".join(character for character in value if not character.isspace())


def names_mask(payload: str, zero_names: set[str]) -> int:
    mask = 0
    for item in split_entries(payload):
        name, _ = entry_pair(item)
        if name in zero_names:
            continue
        mask |= 1 << (fnv(name.encode("utf-8")) % 63)
    return mask


def version(value: str) -> int:
    if not value or value == "never":
        return 0
    pieces = value.split(".", 1)
    if not all(piece.isdigit() for piece in pieces):
        return 0xFFFF_FFFF_FFFF_FFFF
    major = int(pieces[0])
    minor = int(pieces[1]) if len(pieces) == 2 else 0
    if major > 0xFFFF_FFFF or minor > 0xFFFF_FFFF:
        return 0xFFFF_FFFF_FFFF_FFFF
    return (major << 32) | minor


def declaration_contract(record: dict[str, object], source: bytes) -> dict[str, object]:
    attachment = record["attachment"]
    kind = str(attachment["kind"])
    name = str(attachment["name"])
    name_start, name_length = attachment["nameSpan"]
    text = source.decode("utf-8", "strict")
    params: list[int] = []
    return_identity = 0
    declaration_end = len(text)

    # This scanner only transports names and type spellings from the exact
    # declaration selected by the native DocParser. Type validity and all
    # comparisons remain native; this is not a source parser or typechecker.
    if kind == "function":
        cursor = skip_space(text, name_start + name_length)
        if cursor >= len(text) or text[cursor] != "(":
            raise ValidationError("resolved function declaration has no parameter list")
        cursor += 1
        param_start = cursor
        depth = 0
        raw_params: list[str] = []
        while cursor < len(text):
            char = text[cursor]
            if char == "<":
                depth += 1
            elif char == ">":
                depth -= 1
            elif char == "," and depth == 0:
                raw_params.append(text[param_start:cursor])
                param_start = cursor + 1
            elif char == ")" and depth == 0:
                raw_params.append(text[param_start:cursor])
                break
            cursor += 1
        else:
            raise ValidationError("unterminated resolved parameter list")
        type_by_name: dict[str, str] = {}
        for raw in raw_params:
            token = normalized(raw)
            if not token:
                continue
            declaration_identity = token
            typed_name = token.split("=", 1)[0]
            dot = typed_name.rfind(".")
            if dot <= 0 or dot == len(typed_name) - 1:
                raise ValidationError("resolved parameter lacks Type.name identity")
            type_name, param_name = typed_name[:dot], typed_name[dot + 1:]
            type_by_name[param_name] = type_name
            params.append(fnv(declaration_identity.encode("utf-8")))
        if len(params) > 4:
            raise ValidationError("resolved function exceeds DocRecordV1 parameter capacity")
        cursor = skip_space(text, cursor + 1)
        if text[cursor:cursor + 2] == "->":
            cursor = skip_space(text, cursor + 2)
            start = cursor
            generic = 0
            while cursor < len(text):
                char = text[cursor]
                if char == "<":
                    generic += 1
                elif char == ">":
                    generic -= 1
                elif generic == 0 and (char.isspace() or char == "{"):
                    break
                cursor += 1
            result_type = normalized(text[start:cursor])
            if result_type:
                return_identity = fnv(result_type.encode("utf-8"))
        brace = text.find("{", cursor)
        if brace >= 0:
            close = text.rfind("}")
            declaration_end = close + 1 if close >= brace else len(text)
            if not return_identity:
                marker = text.find(".return", brace, declaration_end)
                if marker >= 0:
                    begin = marker
                    while begin > brace and (text[begin - 1].isalnum() or text[begin - 1] == "_"):
                        begin -= 1
                    returned = text[begin:marker]
                    if returned in type_by_name:
                        return_identity = fnv(type_by_name[returned].encode("utf-8"))
                    elif returned.isdigit():
                        return_identity = fnv(b"Int")
                    elif returned in {"true", "false"}:
                        return_identity = fnv(b"Bool")

    material = bytearray(kind.encode("utf-8"))
    material.extend(b"\0")
    material.extend(name.encode("utf-8"))
    for identity in params:
        material.extend(struct.pack("<Q", identity))
    material.extend(struct.pack("<Q", return_identity))
    return {
        "params": params,
        "return": return_identity,
        "errors": 0,
        "effects": 0,
        "capabilities": 0,
        "ownership": 0,
        "complexity": 0,
        "requiredRisks": 0,
        "span": packed_span(int(record["sourceSpan"][0]) + int(record["sourceSpan"][1]), max(1, declaration_end - (int(record["sourceSpan"][0]) + int(record["sourceSpan"][1])))),
        "signature": fnv(bytes(material)),
    }


def documented_contract(record: dict[str, object]) -> dict[str, object]:
    text = record["text"]
    parameters: list[int] = []
    for item in split_entries(str(text.get("parameters", ""))):
        name, type_spec = entry_pair(item)
        if name and type_spec:
            type_spec = normalized(type_spec)
            if "=" in type_spec:
                type_name, default = type_spec.split("=", 1)
                identity = f"{type_name}.{name}={default}"
            else:
                identity = f"{type_spec}.{name}"
            parameters.append(fnv(identity.encode("utf-8")))
    return_value = 0
    returns = split_entries(str(text.get("returns", "")))
    if returns:
        _, type_name = entry_pair(returns[0])
        if type_name:
            return_value = fnv(normalized(type_name).encode("utf-8"))
    ownership_text = normalized(str(text.get("ownership", "")))
    complexity_text = normalized(str(text.get("complexity", "")))
    return {
        "params": parameters,
        "return": return_value,
        "errors": names_mask(str(text.get("errors", "")), {"none"}),
        "effects": names_mask(str(text.get("effects", "")), {"none", "pure"}),
        "capabilities": names_mask(str(text.get("capabilities", "")), {"none"}),
        "ownership": 0 if ownership_text in {"", "none;"} else fnv(ownership_text.encode("utf-8")),
        "complexity": 0 if not complexity_text else fnv(complexity_text.encode("utf-8")),
        "risks": names_mask(str(text.get("risks", "")), {"none"}),
        "since": version(str(text.get("since", ""))),
        "deprecated": version(str(text.get("deprecated", ""))),
    }


def native_validate(record: dict[str, object], source: bytes, strict: bool, previous: int) -> list[dict[str, object]]:
    doc = documented_contract(record)
    symbol = declaration_contract(record, source)
    params = list(doc["params"])[:4] + [0] * 4
    symbol_params = list(symbol["params"])[:4] + [0] * 4
    start, length = record["sourceSpan"]
    words = [
        MAGIC, 1, int(record["symbolId"]), int(record["fieldMask"]), 1,
        len(doc["params"]), len(symbol["params"]), *params[:4], *symbol_params[:4],
        int(doc["return"]), int(symbol["return"]), int(doc["errors"]), int(symbol["errors"]),
        int(doc["effects"]), int(symbol["effects"]), int(doc["capabilities"]), int(symbol["capabilities"]),
        int(doc["ownership"]), int(symbol["ownership"]), int(doc["complexity"]), int(symbol["complexity"]),
        int(doc["risks"]), int(symbol["requiredRisks"]), int(doc["since"]), int(doc["deprecated"]),
        1 << 32, 0, 1, packed_span(int(start), int(length)), int(symbol["span"]),
        int(symbol["signature"]), previous, 1 if strict else 0, 1,
    ]
    if len(words) != 40:
        raise ValidationError("internal DocValidationRequest layout mismatch")
    result = subprocess.run(
        [str(VALIDATOR)], input=REQUEST.pack(*words), stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=10, check=False, env={},
    )
    if result.returncode or result.stderr or len(result.stdout) != REPORT_BYTES:
        raise ValidationError("native DocValidator rejected its resolved request")
    issues: list[dict[str, object]] = []
    for offset in range(0, REPORT_BYTES, ISSUE.size):
        code, severity, symbol_id, primary, related, expected, observed, fix = ISSUE.unpack_from(result.stdout, offset)
        if not code:
            continue
        stable_code, message = ISSUE_CODES[int(code)]
        issue: dict[str, object] = {
            "code": stable_code,
            "severity": "error" if severity == 2 else "warning",
            "message": message,
            "symbolId": symbol_id,
            "primary": unpack_span(primary),
            "related": unpack_span(related),
            "expectedIdentity": f"0x{expected:016x}",
            "observedIdentity": f"0x{observed:016x}",
            "issueIdentity": f"{stable_code}:{symbol_id:016x}:{primary:016x}:{related:016x}",
        }
        if fix == 1:
            issue["fix"] = {"kind": "scaffold", "mechanical": True, "applied": False}
        elif fix == 2:
            issue["fix"] = {"kind": "rename", "mechanical": True, "applied": False}
        issues.append(issue)
    return issues


def source_paths(values: list[str]) -> list[Path]:
    selected: list[Path] = []
    for raw in values:
        path = Path(raw)
        if path.is_dir():
            selected.extend(item for item in path.rglob("*.no") if item.is_file() and not item.is_symlink())
        else:
            selected.append(path)
    return sorted({path.absolute() for path in selected}, key=lambda path: str(path))


def missing_issue(path: Path, data: bytes) -> dict[str, object]:
    code, message = ISSUE_CODES[15]
    identity = hashlib.sha256(data).hexdigest()[:16]
    return {
        "code": code, "severity": "warning", "message": message,
        "symbolId": 0, "primary": [0, min(len(data), 1)], "related": None,
        "expectedIdentity": "semantic-doc", "observedIdentity": "missing",
        "issueIdentity": f"{code}:{identity}:0",
        "fix": {"kind": "scaffold", "mechanical": True, "applied": False},
        "source": str(path),
    }


def validate_paths(paths: list[str], strict: bool, previous: int) -> tuple[list[dict[str, object]], int, int]:
    issues: list[dict[str, object]] = []
    documented = 0
    selected = source_paths(paths)
    for path in selected:
        resolved, data, identity = read_source(str(path))
        before = hashlib.sha256(data).digest()
        record = doc_record(resolved, data)
        if record is None:
            issues.append(missing_issue(resolved, data))
        else:
            documented += 1
            current = native_validate(record, data, strict, previous)
            for issue in current:
                issue["source"] = str(resolved)
            issues.extend(current)
        after_path, after, after_identity = read_source(str(path))
        if after_path != resolved or identity != after_identity or hashlib.sha256(after).digest() != before:
            raise ValidationError("check-docs observed source mutation or path replacement")
    return issues, documented, len(selected)


def render_text(issues: list[dict[str, object]]) -> str:
    lines: list[str] = []
    for issue in issues:
        primary = issue["primary"]
        related = issue["related"]
        relation = "NONE" if related is None else f"{issue['source']}:byte={related[0]}..{related[0] + related[1]}"
        fix = issue.get("fix", {}).get("kind", "none")
        lines.append(
            f"{issue['code']}: {issue['severity']}: {issue['message']}; "
            f"primary={issue['source']}:byte={primary[0]}..{primary[0] + primary[1]}; "
            f"related={relation}; identity={issue['issueIdentity']}; fix={fix}"
        )
    return "\n".join(lines) + ("\n" if lines else "")


def render_sarif(issues: list[dict[str, object]]) -> dict[str, object]:
    results = []
    for issue in issues:
        start, length = issue["primary"]
        result: dict[str, object] = {
            "ruleId": issue["code"], "level": issue["severity"],
            "message": {"text": issue["message"]},
            "partialFingerprints": {"issueIdentity": issue["issueIdentity"]},
            "locations": [{"physicalLocation": {"artifactLocation": {"uri": issue["source"]}, "region": {"byteOffset": start, "byteLength": length}}}],
        }
        if issue["related"] is not None:
            related_start, related_length = issue["related"]
            result["relatedLocations"] = [{"id": 1, "physicalLocation": {"artifactLocation": {"uri": issue["source"]}, "region": {"byteOffset": related_start, "byteLength": related_length}}}]
        results.append(result)
    return {"version": "2.1.0", "$schema": "https://json.schemastore.org/sarif-2.1.0.json", "runs": [{"tool": {"driver": {"name": "neboc-doc-validator"}}, "results": results}]}


def render_lsp(issues: list[dict[str, object]]) -> dict[str, object]:
    diagnostics = []
    for issue in issues:
        start, length = issue["primary"]
        diagnostics.append({
            "code": issue["code"], "severity": 1 if issue["severity"] == "error" else 2,
            "message": issue["message"], "source": "neboc-doc-validator",
            "range": {"start": {"byte": start}, "end": {"byte": start + length}},
            "data": {"issueIdentity": issue["issueIdentity"], "related": issue["related"]},
        })
    return {"schema": 1, "kind": "lsp-publishDiagnostics", "diagnostics": diagnostics}


def main(arguments: list[str]) -> int:
    if not arguments or arguments[0] not in {"check-docs", "lint"}:
        raise ValidationError("expected check-docs or lint --group docs")
    command = arguments[0]
    parser = argparse.ArgumentParser(prog=f"neboc {command}")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--deny", choices=("warnings",))
    parser.add_argument("--report", "--format", dest="report", choices=("text", "json", "lsp", "sarif"), default="text")
    parser.add_argument("--group", choices=("docs",))
    parser.add_argument("--previous-signature", default="0")
    options = parser.parse_args(arguments[1:])
    if command == "lint" and options.group != "docs":
        raise ValidationError("lint requires --group docs")
    try:
        previous = int(options.previous_signature, 0)
    except ValueError as error:
        raise ValidationError("previous signature must be an integer identity") from error
    issues, documented, total = validate_paths(options.paths, bool(options.deny), previous)
    envelope = {
        "schema": 1, "command": command, "group": "docs",
        "issues": issues, "issueCount": len(issues),
        "coverage": {"documented": documented, "total": total},
        "sourceMutation": False,
        "owners": {"record": "DocRecord", "validator": "compiler/semantic/docs/doc_*validator.asm", "policy": "DocValidationPolicyV1"},
    }
    if options.report == "json":
        print(json.dumps(envelope, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    elif options.report == "sarif":
        print(json.dumps(render_sarif(issues), sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    elif options.report == "lsp":
        print(json.dumps(render_lsp(issues), sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    else:
        sys.stdout.write(render_text(issues))
    has_error = any(issue["severity"] == "error" for issue in issues)
    return 1 if has_error or (issues and options.deny == "warnings") else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (ValidationError, OSError, UnicodeError, subprocess.TimeoutExpired) as error:
        print(f"NEBO-RF166-G157-IO: {error}; note=no source was changed", file=sys.stderr)
        raise SystemExit(2)
