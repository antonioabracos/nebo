#!/usr/bin/env python3
"""Read-only operator diagnostics and editor metadata from the canonical Registry."""
from __future__ import annotations

import csv
from dataclasses import dataclass
import hashlib
import io
import json
from pathlib import Path
import re
from typing import Iterable


ROOT = Path(__file__).resolve().parents[2]
REGISTRY_PATH = ROOT / "docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv"
REGISTRY_SHA256 = "b7e5694ceadf30ccffb4077c994fe230d2a10201b64dc6e9e218bdcf4b157f14"
REGISTRY_ROWS = 185
CLASS_COUNTS = {
    "CORE_ALWAYS_ON": 47,
    "UNICODE_ALIAS": 9,
    "DOMAIN_GATED": 80,
    "RESERVED": 23,
    "REJECTED": 26,
}
CLASS_ORDER = {name: index for index, name in enumerate(CLASS_COUNTS)}
DIAGNOSTIC_NAMESPACE = 148100
CATEGORIES = {
    "precedence": 1,
    "context": 2,
    "type": 3,
    "effect": 4,
    "capability": 5,
    "reserved": 6,
    "rejected": 7,
    "security": 8,
    "domain": 9,
}
SEMANTIC_MODIFIERS = {
    "UNICODE_ALIAS": 1,
    "DOMAIN_GATED": 2,
    "RESERVED": 4,
    "REJECTED": 4,
}
_PRECEDENCE = re.compile(r"^P(\d{3})_")


class OperatorToolError(ValueError):
    """A stable, user-facing operator tooling failure."""


@dataclass(frozen=True)
class RegistryEntry:
    fields: dict[str, str]
    line: int

    def __getitem__(self, key: str) -> str:
        return self.fields[key]


def _canonical(value: str) -> str | None:
    value = value.strip()
    return None if not value or value == "N/A" else value


def _is_literal_lexeme(value: str) -> bool:
    """Keep only exact spellings; prose and metavariable patterns are excluded."""
    if value == "xor":
        return True
    if not value or any(char.isspace() for char in value):
        return False
    if "..." in value or any(char in value for char in "Rxy"):
        return False
    if any(char.isalpha() for char in value):
        return value == "xor"
    return True


class OperatorRegistry:
    """Validated, immutable view over the single canonical Registry TSV."""

    def __init__(self, path: Path = REGISTRY_PATH) -> None:
        raw = path.read_bytes()
        if hashlib.sha256(raw).hexdigest() != REGISTRY_SHA256:
            raise OperatorToolError("REGISTRY_DIGEST_MISMATCH")
        try:
            text = raw.decode("utf-8", "strict")
        except UnicodeDecodeError as exc:
            raise OperatorToolError("REGISTRY_UTF8_INVALID") from exc
        reader = csv.DictReader(io.StringIO(text), delimiter="\t")
        required = {
            "id", "cls", "lexeme", "name", "context", "fixity", "arity",
            "precedence", "associativity", "canonical_ascii", "domain",
            "current_state", "target_state", "description",
        }
        if reader.fieldnames is None or not required.issubset(reader.fieldnames):
            raise OperatorToolError("REGISTRY_SCHEMA_MISMATCH")
        entries = [RegistryEntry(dict(row), number) for number, row in enumerate(reader, start=2)]
        if len(entries) != REGISTRY_ROWS:
            raise OperatorToolError("REGISTRY_ROW_COUNT_MISMATCH")
        self.path = path
        self.entries = tuple(entries)
        self.by_id = {entry["id"]: entry for entry in entries}
        if len(self.by_id) != len(entries):
            raise OperatorToolError("REGISTRY_ID_DUPLICATE")
        counts = {name: 0 for name in CLASS_COUNTS}
        for entry in entries:
            identifier, cls = entry["id"], entry["cls"]
            if cls not in counts:
                raise OperatorToolError("REGISTRY_CLASS_UNKNOWN")
            counts[cls] += 1
            expected_prefix = {
                "CORE_ALWAYS_ON": "NSR-CORE-", "UNICODE_ALIAS": "NSR-UA-",
                "DOMAIN_GATED": "NSR-DOM-", "RESERVED": "NSR-RES-",
                "REJECTED": "NSR-REJ-",
            }[cls]
            if not identifier.startswith(expected_prefix):
                raise OperatorToolError("REGISTRY_CLASS_ID_MISMATCH")
        if counts != CLASS_COUNTS:
            raise OperatorToolError("REGISTRY_CLASS_COUNT_MISMATCH")
        lexemes: dict[str, list[RegistryEntry]] = {}
        for entry in entries:
            if _is_literal_lexeme(entry["lexeme"]):
                lexemes.setdefault(entry["lexeme"], []).append(entry)
        self.lexemes = {
            lexeme: tuple(sorted(rows, key=self._entry_priority))
            for lexeme, rows in lexemes.items()
        }
        self.literal_lexemes = tuple(sorted(self.lexemes, key=lambda item: (-len(item), item)))

    @staticmethod
    def _entry_priority(entry: RegistryEntry) -> tuple[int, int, str]:
        state_rank = 0 if entry["current_state"].startswith(("ACTIVE_CURRENT", "PARTIAL_ACTIVE_CURRENT")) else 1
        return state_rank, CLASS_ORDER[entry["cls"]], entry["id"]

    def get(self, identifier: str) -> RegistryEntry:
        if identifier not in self.by_id:
            raise OperatorToolError("REGISTRY_ID_UNKNOWN")
        return self.by_id[identifier]

    def candidates(self, lexeme: str) -> tuple[RegistryEntry, ...]:
        return self.lexemes.get(lexeme, ())

    def operator_at(self, text: str, offset: int) -> tuple[RegistryEntry, int, int] | None:
        if not (0 <= offset <= len(text)):
            raise OperatorToolError("SOURCE_POSITION_OUTSIDE_DOCUMENT")
        matches: list[tuple[int, RegistryEntry, int, int]] = []
        for lexeme in self.literal_lexemes:
            start_min = max(0, offset - len(lexeme))
            start_max = min(offset, len(text) - len(lexeme))
            for start in range(start_min, start_max + 1):
                end = start + len(lexeme)
                if text[start:end] != lexeme or not (start <= offset < end):
                    continue
                if lexeme == "xor":
                    before = text[start - 1] if start else ""
                    after = text[end] if end < len(text) else ""
                    if before.isalnum() or before == "_" or after.isalnum() or after == "_":
                        continue
                matches.append((len(lexeme), self.lexemes[lexeme][0], start, end))
        if not matches:
            return None
        _, entry, start, end = min(matches, key=lambda item: (-item[0], self._entry_priority(item[1])))
        return entry, start, end

    def scan(self, text: str, limit: int = 256) -> list[tuple[RegistryEntry, int, int]]:
        """Longest-match exact Registry view for editor decoration, never semantics."""
        result: list[tuple[RegistryEntry, int, int]] = []
        cursor = 0
        while cursor < len(text) and len(result) < limit:
            selected: tuple[RegistryEntry, int] | None = None
            for lexeme in self.literal_lexemes:
                if text.startswith(lexeme, cursor):
                    if lexeme == "xor":
                        before = text[cursor - 1] if cursor else ""
                        after_at = cursor + len(lexeme)
                        after = text[after_at] if after_at < len(text) else ""
                        if before.isalnum() or before == "_" or after.isalnum() or after == "_":
                            continue
                    selected = self.lexemes[lexeme][0], len(lexeme)
                    break
            if selected is None:
                cursor += 1
                continue
            entry, width = selected
            result.append((entry, cursor, cursor + width))
            cursor += width
        return result

    @staticmethod
    def default_category(entry: RegistryEntry) -> str:
        return {
            "CORE_ALWAYS_ON": "precedence",
            "UNICODE_ALIAS": "precedence",
            "DOMAIN_GATED": "domain",
            "RESERVED": "reserved",
            "REJECTED": "rejected",
        }[entry["cls"]]

    @staticmethod
    def migration(entry: RegistryEntry) -> dict[str, object] | None:
        canonical = _canonical(entry["canonical_ascii"])
        if canonical is None or canonical == entry["lexeme"]:
            return None
        exact_alias = entry["cls"] == "UNICODE_ALIAS" and entry["precedence"] == "SAME_AS_ASCII"
        return {
            "kind": "replaceSpelling",
            "replacement": canonical,
            "safe": exact_alias,
            "automatic": False,
            "equivalence": "registry-same-as-ascii" if exact_alias else "not-proven",
            "requiresReview": not exact_alias,
        }

    def diagnostic(
        self,
        identifier: str,
        *,
        category: str | None = None,
        source_id: int = 0,
        start: int = 0,
        end: int = 0,
    ) -> dict[str, object]:
        entry = self.get(identifier)
        category = category or self.default_category(entry)
        if category not in CATEGORIES:
            raise OperatorToolError("DIAGNOSTIC_CATEGORY_UNKNOWN")
        if source_id < 0 or start < 0 or end < start:
            raise OperatorToolError("SOURCE_SPAN_INVALID")
        match = _PRECEDENCE.match(entry["precedence"])
        precedence = int(match.group(1)) if match else None
        associativity = entry["associativity"]
        right_bp = precedence
        if precedence is not None and associativity.startswith(("left", "non-associative")):
            right_bp += 1
        parenthesize = associativity.startswith("non-associative")
        code_number = DIAGNOSTIC_NAMESPACE + CATEGORIES[category]
        severity = "warning" if entry["cls"] in {"CORE_ALWAYS_ON", "UNICODE_ALIAS"} else "error"
        return {
            "schema": 1,
            "namespace": "NEBO_OPERATOR",
            "code": f"NEBO-OP-{code_number}",
            "severity": severity,
            "category": category,
            "registryId": entry["id"],
            "class": entry["cls"],
            "lexeme": entry["lexeme"],
            "codePoints": [f"U+{ord(char):04X}" for char in entry["lexeme"]],
            "canonicalForm": _canonical(entry["canonical_ascii"]),
            "name": entry["name"],
            "context": entry["context"],
            "fixity": entry["fixity"],
            "arity": entry["arity"],
            "precedence": entry["precedence"],
            "associativity": associativity,
            "domain": entry["domain"],
            "currentState": entry["current_state"],
            "targetState": entry["target_state"],
            "span": {"sourceId": source_id, "start": start, "end": end},
            "parse": {
                "leftBindingPower": precedence,
                "rightBindingPower": right_bp,
                "parenthesize": parenthesize,
                "tree": "structural-or-domain-grammar" if precedence is None else f"{entry['fixity']}({precedence},{right_bp})",
            },
            "message": entry["description"],
            "action": self.migration(entry),
            "registrySource": {
                "uri": self.path.resolve().as_uri(),
                "line": entry.line,
                "sha256": REGISTRY_SHA256,
            },
        }


def _json_bytes(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def lsp_payload(facts: dict[str, object]) -> dict[str, object]:
    span = facts["span"]
    assert isinstance(span, dict)
    source = facts["registrySource"]
    assert isinstance(source, dict)
    action = facts["action"]
    code_actions = []
    if isinstance(action, dict):
        code_actions.append({
            "title": f"Use canonical operator {action['replacement']}",
            "kind": "quickfix.nebo.operator",
            "isPreferred": bool(action["safe"]),
            "data": {"operator": facts, "migration": action},
        })
    line = int(source["line"]) - 1
    return {
        "diagnostic": {
            "range": {"start": {"line": 0, "character": int(span["start"])},
                      "end": {"line": 0, "character": int(span["end"])}},
            "severity": 2 if facts["severity"] == "warning" else 1,
            "code": facts["code"],
            "source": "neboc",
            "message": facts["message"],
            "data": {"operator": facts},
        },
        "hover": {"contents": {"kind": "markdown", "value": operator_markdown(facts)}},
        "signatureHelp": {
            "signatures": [{"label": f"{facts['lexeme']} [{facts['fixity']}; arity {facts['arity']}]",
                            "documentation": facts["message"]}],
            "activeSignature": 0,
            "activeParameter": 0,
        },
        "semanticToken": {
            "type": "operator",
            "modifiers": semantic_modifier_names(str(facts["class"])),
        },
        "definition": {
            "uri": source["uri"],
            "range": {"start": {"line": line, "character": 0},
                      "end": {"line": line, "character": 0}},
        },
        "codeActions": code_actions,
    }


def operator_markdown(facts: dict[str, object]) -> str:
    return (
        f"`{facts['lexeme']}` — **{facts['registryId']}**\n\n"
        f"class: `{facts['class']}` · state: `{facts['currentState']}`\n\n"
        f"fixity: `{facts['fixity']}` · precedence: `{facts['precedence']}` · "
        f"associativity: `{facts['associativity']}`\n\n{facts['message']}"
    )


def semantic_modifier_names(cls: str) -> list[str]:
    return {
        "UNICODE_ALIAS": ["unicodeAlias"],
        "DOMAIN_GATED": ["domainGated", "inactive"],
        "RESERVED": ["inactive"],
        "REJECTED": ["inactive"],
    }.get(cls, [])


def render(facts: dict[str, object], format_name: str) -> bytes:
    if format_name == "json":
        return _json_bytes(facts) + b"\n"
    if format_name in {"jsonl", "json-lines"}:
        return _json_bytes({"diagnostic": facts}) + b"\n"
    if format_name == "lsp":
        return _json_bytes(lsp_payload(facts)) + b"\n"
    if format_name == "sarif":
        span = facts["span"]
        assert isinstance(span, dict)
        level = "warning" if facts["severity"] == "warning" else "error"
        document = {
            "version": "2.1.0",
            "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
            "runs": [{
                "tool": {"driver": {"name": "neboc", "semanticVersion": "1"}},
                "results": [{
                    "ruleId": facts["code"],
                    "level": level,
                    "message": {"text": facts["message"]},
                    "locations": [{"physicalLocation": {"region": {
                        "byteOffset": int(span["start"]),
                        "byteLength": int(span["end"]) - int(span["start"]),
                    }}}],
                    "properties": {"operator": facts},
                }],
            }],
        }
        return _json_bytes(document) + b"\n"
    if format_name == "terminal":
        keys: Iterable[str] = (
            "code", "severity", "category", "registryId", "class", "lexeme",
            "canonicalForm", "fixity", "precedence", "associativity",
            "currentState", "targetState", "span", "parse", "action",
        )
        rows = [f"{key}={json.dumps(facts[key], ensure_ascii=False, sort_keys=True, separators=(',', ':'))}" for key in keys]
        rows.append(f"facts={_json_bytes(facts).decode('utf-8')}")
        return ("\n".join(rows) + "\n").encode("utf-8")
    raise OperatorToolError("OUTPUT_FORMAT_UNKNOWN")


def canonical_digest(facts: dict[str, object]) -> str:
    return hashlib.sha256(_json_bytes(facts)).hexdigest()
