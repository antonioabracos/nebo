#!/usr/bin/env python3
"""Independent stdlib oracle for RF27-G18-F09 closeout facts."""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import struct
import sys
from pathlib import Path

MAGIC = 0x4E42504631384639
WORDS = (
    MAGIC,
    1,
    9,
    0x4008000000000000,
    4,
    2,
    2,
    3,
    0x4018000000000000,
    0,
    29,
    2,
    5,
    3,
    4,
    19,
    61,
    1,
    61,
    63,
)
GOLDEN = struct.pack("<20Q", *WORDS)
FIELD_NAMES = (
    "magic", "version", "abs_i64", "sqrt_f64_bits", "matrix_rows",
    "matrix_cols", "tensor_rank", "tensor_axis1", "kernel_add_bits",
    "planner_tier", "console_length", "console_lines", "ui_nodes",
    "accessibility_role", "chart_series", "chart_points", "chart_commands",
    "frame_sequence", "present_commands", "cleanup_mask",
)


def verify_summary(data: bytes) -> None:
    if len(data) != len(GOLDEN):
        raise SystemExit(f"SUMMARY_SIZE actual={len(data)} expected={len(GOLDEN)}")
    actual = struct.unpack("<20Q", data)
    if actual != WORDS:
        mismatches = [
            f"{FIELD_NAMES[i]}:{a:#x}!={e:#x}"
            for i, (a, e) in enumerate(zip(actual, WORDS)) if a != e
        ]
        raise SystemExit("SUMMARY_MISMATCH " + " ".join(mismatches))


def property_model(seed: int, cases: int) -> tuple[str, dict[str, int]]:
    rng = random.Random(seed)
    counters = {
        "cases": cases,
        "numeric": 0,
        "matrix_tensor": 0,
        "kernel": 0,
        "visual": 0,
        "rejected_bounds": 0,
        "cleanup": 0,
    }
    h = hashlib.sha256()
    for index in range(cases):
        domain = rng.randrange(5)
        if domain == 0:
            value = rng.randint(-(1 << 63) + 1, (1 << 63) - 1)
            absolute = abs(value)
            counters["numeric"] += 1
            record = (domain, value & ((1 << 64) - 1), absolute)
        elif domain == 1:
            rows = rng.randrange(0, 70)
            cols = rng.randrange(0, 70)
            rank = rng.randrange(0, 8)
            accepted = int(1 <= rows <= 64 and 1 <= cols <= 64 and 1 <= rank <= 6)
            if not accepted:
                counters["rejected_bounds"] += 1
            counters["matrix_tensor"] += 1
            record = (domain, rows, cols, rank, accepted)
        elif domain == 2:
            elements = rng.randrange(0, 5000)
            features = rng.randrange(0, 8)
            if elements > 4096:
                tier = 0xFF
                counters["rejected_bounds"] += 1
            elif elements < 4 or not (features & 1):
                tier = 0
            elif elements < 8 or not (features & 2):
                tier = 1
            else:
                tier = 2
            counters["kernel"] += 1
            record = (domain, elements, features, tier)
        elif domain == 3:
            series = rng.randrange(0, 36)
            points = rng.randrange(0, 5000)
            commands = rng.randrange(0, 9000)
            accepted = int(series <= 32 and points <= 4096 and commands <= 8192)
            if not accepted:
                counters["rejected_bounds"] += 1
            counters["visual"] += 1
            record = (domain, series, points, commands, accepted)
        else:
            resources = rng.randrange(1, 7)
            released = (1 << resources) - 1
            counters["cleanup"] += 1
            record = (domain, resources, released)
        h.update(index.to_bytes(4, "little"))
        h.update(repr(record).encode("ascii"))
        h.update(b"\n")
    return h.hexdigest(), counters


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--golden", action="store_true")
    parser.add_argument("--verify", type=Path)
    parser.add_argument("--properties", action="store_true")
    parser.add_argument("--seed", default="0x271809")
    parser.add_argument("--cases", type=int, default=5000)
    args = parser.parse_args()

    if args.golden:
        sys.stdout.buffer.write(GOLDEN)
        return
    if args.verify is not None:
        verify_summary(args.verify.read_bytes())
        print("RF27_G18_F09_SUMMARY_VERIFY=PASS fields=20 bytes=160")
        return
    if args.properties:
        seed = int(args.seed, 0)
        digest, counters = property_model(seed, args.cases)
        ordered = " ".join(f"{key}={value}" for key, value in counters.items())
        print(
            f"RF27_G18_F09_PROGRAM_MODEL=PASS seed={seed:#x} cases={args.cases} "
            f"digest={digest} {ordered}"
        )
        print(json.dumps({"seed": seed, "sha256": digest, **counters}, sort_keys=True))
        return

    verify_summary(GOLDEN)
    print("RF27_G18_F09_ORACLE_SELFTEST=PASS fields=20 bytes=160")


if __name__ == "__main__":
    main()
