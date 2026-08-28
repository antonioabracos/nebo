#!/usr/bin/env python3
"""Generate and structurally verify the Nebo v1.0 public callable atlas.

The manifest is self-contained: every authenticated source is embedded as
base64 and hash-bound.  No build, backup, fixture-name, or absolute repository
path is needed to regenerate the atlas in a clean or moved root.
"""
from __future__ import annotations

import argparse
import base64
import csv
import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tests/public-api/nebo-v1.0-public-callable-atlas/manifest.tsv"
DEFAULT_OUTPUT = ROOT / "examples/conformance/nebo-v1.0-public-callable-atlas.no"
FIELDNAMES = ("record_kind", "record_id", "parent_id", "ordinal", "metadata_b64", "source_b64", "source_sha256")


class ManifestError(RuntimeError):
    pass


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def decode_b64(value: str, label: str) -> bytes:
    try:
        return base64.b64decode(value.encode("ascii"), validate=True)
    except Exception as exc:
        raise ManifestError(f"invalid base64 for {label}") from exc


def load_manifest(path: Path) -> list[dict[str, object]]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if tuple(reader.fieldnames or ()) != FIELDNAMES:
            raise ManifestError("manifest header mismatch")
        raw = list(reader)
    if not raw:
        raise ManifestError("empty manifest")
    seen: set[tuple[str, str]] = set()
    records: list[dict[str, object]] = []
    for row in raw:
        kind = row["record_kind"]
        record_id = row["record_id"]
        if kind not in {"GROUP", "SUBGROUP", "VARIANT", "PRELUDE"}:
            raise ManifestError(f"unknown record kind {kind}")
        key = (kind, record_id)
        if key in seen:
            raise ManifestError(f"duplicate record {kind}:{record_id}")
        seen.add(key)
        try:
            ordinal = int(row["ordinal"])
        except ValueError as exc:
            raise ManifestError(f"invalid ordinal for {kind}:{record_id}") from exc
        metadata_bytes = decode_b64(row["metadata_b64"], f"{kind}:{record_id}:metadata")
        try:
            metadata = json.loads(metadata_bytes)
        except json.JSONDecodeError as exc:
            raise ManifestError(f"invalid metadata JSON for {kind}:{record_id}") from exc
        source = decode_b64(row["source_b64"], f"{kind}:{record_id}:source") if row["source_b64"] else b""
        if source:
            if sha256(source) != row["source_sha256"]:
                raise ManifestError(f"source hash mismatch for {kind}:{record_id}")
        elif row["source_sha256"] not in {"", sha256(b"")}:
            raise ManifestError(f"unexpected empty-source hash for {kind}:{record_id}")
        records.append({"kind": kind, "id": record_id, "parent": row["parent_id"], "ordinal": ordinal, "metadata": metadata, "source": source})
    counts = Counter(str(record["kind"]) for record in records)
    expected = {"GROUP": 204, "SUBGROUP": 1634, "VARIANT": 207, "PRELUDE": 23}
    if dict(counts) != expected:
        raise ManifestError(f"cardinality mismatch: {dict(counts)} != {expected}")
    group_ids = {str(record["id"]) for record in records if record["kind"] == "GROUP"}
    subgroup_ids = {str(record["id"]) for record in records if record["kind"] == "SUBGROUP"}
    for record in records:
        if record["kind"] == "SUBGROUP" and record["parent"] not in group_ids:
            raise ManifestError(f"unknown group for {record['id']}")
        if record["kind"] == "VARIANT" and record["parent"] not in subgroup_ids:
            raise ManifestError(f"unknown subgroup for {record['id']}")
    return records


def split_source(text: str) -> tuple[str, str]:
    matches = list(re.finditer(r"\bstart\s*\(\s*\)\s*\{", text))
    if len(matches) != 1:
        raise ManifestError(f"variant source must contain exactly one start, found {len(matches)}")
    match = matches[0]
    opening = text.find("{", match.start())
    depth = 0
    in_string = in_char = escaped = False
    for index in range(opening, len(text)):
        char = text[index]
        if escaped:
            escaped = False
            continue
        if char == "\\" and (in_string or in_char):
            escaped = True
            continue
        if char == '"' and not in_char:
            in_string = not in_string
            continue
        if char == "'" and not in_string:
            in_char = not in_char
            continue
        if in_string or in_char:
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                trailing = text[index + 1 :].strip()
                if trailing and not trailing.startswith("//"):
                    raise ManifestError("variant has content after start")
                return text[: match.start()].strip(), text[opening + 1 : index].strip()
    raise ManifestError("unbalanced start body")


def safe_comment(value: object) -> str:
    text = str(value).replace("\n", " ").replace("\r", " ")
    text = re.sub(r"(?i)\bprint\b", "NON_NEBO_OUTPUT_ALIAS", text)
    text = re.sub(r"(?i)\bstart\s*\(", "STANDALONE_START(", text)
    return text


def rename_module_declarations(ordinal: int, preamble: str, body: str) -> tuple[str, str, dict[str, str]]:
    replacements: dict[str, str] = {}
    for pattern in (r"\benum\s+([A-Za-z_][A-Za-z0-9_]*)", r"\bnewtype\s+([A-Za-z_][A-Za-z0-9_]*)", r"\btype\s+alias\s+([A-Za-z_][A-Za-z0-9_]*)"):
        for old in re.findall(pattern, preamble):
            replacements[old] = f"T{ordinal:06d}"
    for old in re.findall(r"\([^\n{}]*?\.self\)\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(", preamble):
        replacements[old] = f"f{ordinal:06d}"
    for old, new in sorted(replacements.items(), key=lambda item: len(item[0]), reverse=True):
        preamble = re.sub(rf"\b{re.escape(old)}\b", new, preamble)
        body = re.sub(rf"\b{re.escape(old)}\b", new, body)
    return preamble, body, replacements


def rename_locals(ordinal: int, body: str) -> tuple[str, dict[str, str]]:
    names = list(dict.fromkeys(re.findall(r"\.([A-Za-z_][A-Za-z0-9_]*)(?:\.mutable)?\s*;", body)))
    names = [name for name in names if name not in {"return", "mutable", "console"}]
    replacements = {old: f"v{ordinal:03d}{index:02d}" for index, old in enumerate(names, 1)}
    for old, new in sorted(replacements.items(), key=lambda item: len(item[0]), reverse=True):
        body = re.sub(rf"\b{re.escape(old)}\b", new, body)
    return body, replacements


def generate(records: list[dict[str, object]]) -> tuple[str, dict[str, object]]:
    groups = sorted((record for record in records if record["kind"] == "GROUP"), key=lambda record: int(record["ordinal"]))
    subgroups = sorted((record for record in records if record["kind"] == "SUBGROUP"), key=lambda record: int(record["ordinal"]))
    variants = sorted((record for record in records if record["kind"] == "VARIANT"), key=lambda record: int(record["ordinal"]))
    preludes = sorted((record for record in records if record["kind"] == "PRELUDE"), key=lambda record: int(record["ordinal"]))
    output: list[str] = [
        "// NEBO-V1.0 PUBLIC CALLABLE ATLAS — C13-PRC-A2 RUN-009",
        "// GENERATED FROM A HASH-BOUND, SELF-CONTAINED MANIFEST.",
        "// ALL 207 MATERIAL VARIANTS ARE ACTIVE; NO PUBLIC RED IS COMMENTED OUT.",
        "// C13-F27 REMAINS NOT STARTED AND NOT AUTHORIZED.",
        "",
    ]
    by_group: dict[str, list[dict[str, object]]] = {}
    for subgroup in subgroups:
        by_group.setdefault(str(subgroup["parent"]), []).append(subgroup)
    for group in groups:
        metadata = group["metadata"]
        assert isinstance(metadata, dict)
        output.append(f"// ATLAS_GROUP {group['id']} {safe_comment(json.dumps(metadata, sort_keys=True, separators=(',', ':')))}")
        for subgroup in by_group.get(str(group["id"]), []):
            sub_metadata = subgroup["metadata"]
            output.append(f"// ATLAS_SUBGROUP {subgroup['id']} {safe_comment(json.dumps(sub_metadata, sort_keys=True, separators=(',', ':')))}")
        output.append("")
    output.append("// VALUE_PRELUDE_AUTHORITY_BEGIN")
    for prelude in preludes:
        metadata = prelude["metadata"]
        output.append(f"// VALUE_PRELUDE {prelude['id']} {safe_comment(json.dumps(metadata, sort_keys=True, separators=(',', ':')))}")
    output.extend(["// VALUE_PRELUDE_AUTHORITY_END", ""])

    preambles: list[str] = []
    helpers: list[str] = []
    start_items: list[str] = []
    architectures: Counter[str] = Counter()
    top_level_names: list[str] = []
    helper_names: list[str] = []
    local_names: list[str] = []
    for record in variants:
        ordinal = int(record["ordinal"])
        metadata = record["metadata"]
        assert isinstance(metadata, dict)
        source = bytes(record["source"]).decode("utf-8")
        preamble, body = split_source(source)
        preamble, body, module_replacements = rename_module_declarations(ordinal, preamble, body)
        body, local_replacements = rename_locals(ordinal, body)
        top_level_names.extend(module_replacements.values())
        local_names.extend(local_replacements.values())
        if preamble:
            preambles.append(f"// PREAMBLE_BEGIN {record['id']}\n{preamble}\n// PREAMBLE_END {record['id']}")
        architecture = str(metadata.get("composition_class", "HELPER"))
        if architecture not in {"HELPER", "TOP_LEVEL_ONLY_AUTHENTICATED", "INLINE_TOP_LEVEL"}:
            raise ManifestError(f"unknown composition class for {record['id']}: {architecture}")
        architectures[architecture] += 1
        output.append(
            f"// ATLAS_VARIANT {record['id']} callable={safe_comment(metadata.get('callable_id'))} "
            f"name={safe_comment(metadata.get('canonical_name'))} source_sha256={metadata.get('source_sha256')} "
            f"architecture={architecture} expected_exit={metadata.get('expected_exit')}"
        )
        if architecture == "HELPER":
            helper_name = f"a{ordinal:06d}"
            helper_names.append(helper_name)
            has_return = bool(re.search(r"\.return\s*;", body))
            helper = [f"(Int.self){helper_name}(){{"]
            helper.extend("    " + line.rstrip() for line in body.splitlines())
            if not has_return:
                helper.append("    0.return;")
            helper.append("}")
            helpers.append("\n".join(helper))
            start_items.append(f"    // ACTIVE_VARIANT {record['id']} HELPER\n    0.{helper_name}();")
        else:
            direct = re.sub(r"\.return\s*;", ";", body)
            block = [f"    // ACTIVE_VARIANT {record['id']} {architecture}"]
            block.extend("    " + line.rstrip() for line in direct.splitlines())
            start_items.append("\n".join(block))

    output.extend(["", *preambles, "", *helpers, "", "start(){", *start_items, "    0.return;", "}", ""])
    text = "\n".join(output)
    if re.search(r"(?i)\bprint\s*\(", text):
        raise ManifestError("active forbidden output alias")
    if "ENTRYPOINT(" in text:
        raise ManifestError("ENTRYPOINT placeholder leaked")
    summary = {
        "groups": len(groups),
        "subgroups": len(subgroups),
        "variants": len(variants),
        "preludes": len(preludes),
        "architectures": dict(sorted(architectures.items())),
        "start_count": len(re.findall(r"\bstart\s*\(", text)),
        "entrypoint_count": text.count("ENTRYPOINT("),
        "active_variant_count": len(re.findall(r"^    // ACTIVE_VARIANT ", text, re.MULTILINE)),
        "helper_count": len(helper_names),
        "duplicate_helper_names": len(helper_names) - len(set(helper_names)),
        "duplicate_top_level_names": len(top_level_names) - len(set(top_level_names)),
        "duplicate_local_names": len(local_names) - len(set(local_names)),
        "sha256": sha256(text.encode()),
    }
    required = {
        "groups": 204,
        "subgroups": 1634,
        "variants": 207,
        "preludes": 23,
        "start_count": 1,
        "entrypoint_count": 0,
        "active_variant_count": 207,
        "duplicate_helper_names": 0,
        "duplicate_top_level_names": 0,
        "duplicate_local_names": 0,
    }
    for key, expected in required.items():
        if summary[key] != expected:
            raise ManifestError(f"generated {key}={summary[key]}, expected {expected}")
    return text, summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--summary", type=Path)
    args = parser.parse_args()
    try:
        records = load_manifest(args.manifest)
        text, summary = generate(records)
    except (ManifestError, OSError, UnicodeDecodeError) as exc:
        print(f"atlas manifest rejected: {exc}", file=sys.stderr)
        return 2
    if args.check:
        if not args.output.is_file() or args.output.read_bytes() != text.encode():
            print("atlas output differs from deterministic generation", file=sys.stderr)
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    if args.summary:
        args.summary.parent.mkdir(parents=True, exist_ok=True)
        args.summary.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
