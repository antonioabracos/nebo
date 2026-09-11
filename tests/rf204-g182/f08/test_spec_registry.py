#!/usr/bin/env python3
import csv, pathlib, re
root = pathlib.Path(__file__).resolve().parents[3]
spec = root / "docs/public/v1.0/language/specification"
with (spec / "NORMATIVE-RULE-REGISTRY.tsv").open(encoding="utf-8", newline="") as fh: rules = list(csv.DictReader(fh, delimiter="\t"))
with (spec / "SPEC-TO-TEST-TRACE.tsv").open(encoding="utf-8", newline="") as fh: trace = list(csv.DictReader(fh, delimiter="\t"))
assert rules and len(rules) == len(trace) and {r["rule_id"] for r in rules} == {r["rule_id"] for r in trace}
assert len({r["rule_id"] for r in rules}) == len(rules)
text = "\n".join(p.read_text(encoding="utf-8") for p in sorted(spec.glob("*.md")))
assert "`console()` is the canonical public output surface" in text
assert "Imports never grant effects or capabilities" in text
print(f"SPEC_REGISTRY=PASS RULES={len(rules)}")
