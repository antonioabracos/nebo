#!/usr/bin/env python3
from __future__ import annotations
import json, subprocess, tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[3]
tool = root / "scripts/rf204/freeze_diff.py"
with tempfile.TemporaryDirectory() as tmp:
    a = Path(tmp) / "a.tsv"; b = Path(tmp) / "b.tsv"
    a.write_text("id\tvalue\n1\tstable\n", encoding="utf-8")
    b.write_bytes(a.read_bytes())
    same = subprocess.run([str(tool), "api", str(a), str(b), "--json"], text=True, capture_output=True)
    assert same.returncode == 0 and json.loads(same.stdout)["classification"] == "IDENTICAL"
    b.write_text("id\tvalue\n1\tchanged\n", encoding="utf-8")
    changed = subprocess.run([str(tool), "abi", str(a), str(b), "--json"], text=True, capture_output=True)
    assert changed.returncode == 1 and json.loads(changed.stdout)["classification"] == "CHANGED_REVIEW_REQUIRED"
print("RF204_G176_F07_FREEZE_DIFF=PASS")
