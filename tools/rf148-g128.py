#!/usr/bin/env python3
"""Public offline operator Registry inspection and diagnostic renderer."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from compiler.sdk.operator_tooling import CATEGORIES, OperatorRegistry, OperatorToolError, render


def span(raw: str) -> tuple[int, int]:
    try:
        left, right = raw.split(":", 1)
        start, end = int(left), int(right)
    except (ValueError, TypeError) as exc:
        raise argparse.ArgumentTypeError("SPAN_MUST_BE_START:END") from exc
    if start < 0 or end < start:
        raise argparse.ArgumentTypeError("SPAN_INVALID")
    return start, end


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(prog="neboc operator-info", add_help=True)
    value.add_argument("registry_id")
    value.add_argument("--format", choices=("terminal", "json", "jsonl", "json-lines", "lsp", "sarif"), default="terminal")
    value.add_argument("--category", choices=tuple(CATEGORIES))
    value.add_argument("--source-id", type=int, default=0)
    value.add_argument("--span", type=span, default=(0, 0), metavar="START:END")
    return value


def main(arguments: list[str]) -> int:
    options = parser().parse_args(arguments)
    start, end = options.span
    registry = OperatorRegistry()
    facts = registry.diagnostic(
        options.registry_id,
        category=options.category,
        source_id=options.source_id,
        start=start,
        end=end,
    )
    output = render(facts, options.format)
    written = 0
    while written < len(output):
        count = os.write(sys.stdout.fileno(), output[written:])
        if count <= 0:
            raise OSError("OUTPUT_WRITE_FAILED")
        written += count
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (OperatorToolError, OSError) as error:
        print(f"NEBO_OPERATOR_TOOL_ERROR:{error}", file=sys.stderr)
        raise SystemExit(2)
