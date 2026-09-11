#!/usr/bin/env python3
"""Validate labels and executable Nebo blocks in the canonical v1.2 ladder."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[2]
LADDER = ROOT / "docs/roadmaps/NEBO-ESCADA-EVOLUTIVA-AUDITADA-E-CORRIGIDA-v1.2.md"
NEBOC = ROOT / "build/bin/neboc"
LABELS = (
    "EXECUTÁVEL VERIFICADO",
    "CANÓNICO DOCUMENTAL COM GAP",
    "PROPOSTA CONCEPTUAL NÃO CANÓNICA",
    "SEM SINTAXE DEFINIDA",
)


def fail(detail: str) -> None:
    print(f"POST_RC1_LADDER_V12_ERROR detail={detail}", file=sys.stderr)
    raise SystemExit(1)


text = LADDER.read_text(encoding="utf-8")
if ".print(" in text:
    fail("print-alias-present")

steps = re.findall(r"^## Degrau ([0-9]+) — ", text, flags=re.MULTILINE)
if steps != [str(value) for value in range(36)]:
    fail("step-inventory")

lines = text.splitlines()
blocks: list[tuple[str, str, int]] = []
index = 0
while index < len(lines):
    if lines[index] != "```nebo":
        index += 1
        continue
    label = ""
    for previous in reversed(lines[max(0, index - 8) : index]):
        if previous.startswith("### "):
            label = next((candidate for candidate in LABELS if candidate in previous), "")
            break
    if not label:
        fail(f"unlabelled-block-line-{index + 1}")
    end = index + 1
    while end < len(lines) and lines[end] != "```":
        end += 1
    if end == len(lines):
        fail(f"unterminated-block-line-{index + 1}")
    blocks.append((label, "\n".join(lines[index + 1 : end]) + "\n", index + 1))
    index = end + 1

if not blocks:
    fail("no-nebo-blocks")

passed = 0
skipped = 0
with tempfile.TemporaryDirectory(prefix="nebo-ladder-v12-", dir="/tmp") as tmp:
    tmp_path = pathlib.Path(tmp)
    for ordinal, (label, source, line) in enumerate(blocks, start=1):
        if label != "EXECUTÁVEL VERIFICADO":
            skipped += 1
            continue
        source_path = tmp_path / f"block-{ordinal:02d}.no"
        source_path.write_text(source, encoding="utf-8")
        result = subprocess.run(
            [str(NEBOC), "check", str(source_path)],
            cwd=ROOT,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if result.returncode != 0:
            sys.stderr.buffer.write(result.stderr)
            fail(f"block-{ordinal}-line-{line}-exit-{result.returncode}")
        if result.stdout or result.stderr:
            fail(f"block-{ordinal}-unexpected-output")
        passed += 1

print(
    "POST_RC1_LADDER_V12_GREEN "
    f"steps={len(steps)} blocks={len(blocks)} executable_pass={passed} non_executable={skipped}"
)
