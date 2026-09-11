#!/usr/bin/env python3
"""Offline command host for the two G036 compiler tools."""
from __future__ import annotations

import json
from pathlib import Path
import sys
from collections.abc import Mapping

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from compiler.sdk.scientific import (  # noqa: E402
    ScientificError, numeric_report, scientific_bench,
)

MAX_ARTIFACT_BYTES = 65536


def emit(value: object) -> None:
    if isinstance(value, Mapping):
        value = dict(value)
    print(json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False))


def main(argv: list[str]) -> int:
    if len(argv) == 2 and argv[0] == "scientific-bench":
        emit(scientific_bench(argv[1]))
        return 0
    if len(argv) == 2 and argv[0] == "numeric-report":
        path = Path(argv[1])
        try:
            size = path.stat().st_size
            if not path.is_file() or size <= 0 or size > MAX_ARTIFACT_BYTES:
                raise ScientificError("NEBO-G036-REPORT-SIZE", "numeric-report")
            artifact = json.loads(path.read_text(encoding="utf-8"))
        except ScientificError:
            raise
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            raise ScientificError("NEBO-G036-REPORT-READ", "numeric-report") from error
        emit(numeric_report(artifact))
        return 0
    raise ScientificError("NEBO-G036-COMMAND-USAGE", "cli")


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except ScientificError as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(2)
