#!/usr/bin/env python3
"""Fail-closed parser for Buffer-derived semantic capture transcripts."""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

ASSERTION = re.compile(r"NEBO_ASSERT\|([A-Z])\|([A-Z0-9_]+)\|([^|\r\n]+)")
FINAL = re.compile(r"NEBO_TEST_RESULT\|(PASS|FAIL)")


def fail(message: str) -> int:
    print(f"ORACLE_REJECT={message}", file=sys.stderr)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected", required=True, type=Path)
    parser.add_argument("--raw", required=True, type=Path)
    parser.add_argument("--parsed", required=True, type=Path)
    parser.add_argument("--exit-code", required=True)
    args = parser.parse_args()

    if args.exit_code != "0":
        return fail(f"program_exit_{args.exit_code}")

    try:
        raw = args.raw.read_bytes().decode("utf-8", errors="strict")
    except (OSError, UnicodeError) as exc:
        return fail(f"raw_unreadable_{type(exc).__name__}")
    if "FAIL" in raw:
        return fail("fail_token")

    try:
        with args.expected.open(newline="", encoding="utf-8") as handle:
            rows = list(csv.DictReader(handle, delimiter="\t"))
    except OSError as exc:
        return fail(f"expected_unreadable_{type(exc).__name__}")
    if not rows or set(rows[0]) != {"LANE", "KEY", "VALUE"}:
        return fail("expected_schema")
    expected = [(row["LANE"], row["KEY"], row["VALUE"]) for row in rows]
    if len(expected) != len(set((lane, key) for lane, key, _ in expected)):
        return fail("expected_duplicate_key")

    semantic = [line for line in raw.splitlines() if line]
    parsed: list[tuple[str, str, str]] = []
    finals: list[tuple[int, str]] = []
    for index, line in enumerate(semantic):
        match = ASSERTION.fullmatch(line)
        if match:
            parsed.append(match.groups())
            continue
        final = FINAL.fullmatch(line)
        if final:
            finals.append((index, final.group(1)))
            continue
        return fail(f"malformed_line_{index + 1}")

    if len(finals) != 1:
        return fail("final_result_count")
    if finals[0] != (len(semantic) - 1, "PASS"):
        return fail("final_result_not_last_pass")
    if len(parsed) != len(set((lane, key) for lane, key, _ in parsed)):
        return fail("duplicate_key")
    expected_keys = {(lane, key) for lane, key, _ in expected}
    parsed_keys = {(lane, key) for lane, key, _ in parsed}
    if parsed_keys - expected_keys:
        return fail("unknown_key")
    if expected_keys - parsed_keys:
        return fail("missing_key")
    if parsed != expected:
        if [(lane, key) for lane, key, _ in parsed] != [
            (lane, key) for lane, key, _ in expected
        ]:
            return fail("order")
        return fail("value")

    try:
        with args.parsed.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
            writer.writerow(("ORDINAL", "LANE", "KEY", "VALUE", "STATUS"))
            for ordinal, row in enumerate(parsed, 1):
                writer.writerow((ordinal, *row, "PASS"))
    except OSError as exc:
        return fail(f"parsed_unwritable_{type(exc).__name__}")
    print(f"ORACLE_ACCEPT=PASS assertions={len(parsed)} final=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
