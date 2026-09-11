#!/usr/bin/env python3
"""Deterministic structural simulator for NEBO_REFERENCE_BOARD_SIM_V1 images."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--profile", type=Path, required=True)
parser.add_argument("--image", type=Path, required=True)
args = parser.parse_args()

profile = json.loads(args.profile.read_text(encoding="utf-8"))
image = args.image.read_bytes()
assert profile["schema"] == "NEBO_REFERENCE_BOARD_PROFILE-v1"
assert profile["board_id"] == "NEBO_REFERENCE_BOARD_SIM_V1"
assert profile["maturity"] == "SIMULATOR_ONLY"
assert profile["cpu"] == {
    "architecture": "x86_64",
    "model": "nebo-reference-scalar-v1",
    "endianness": "little",
    "clock_hz": 10000000,
}
assert profile["memory"]["initial_stack"] % profile["memory"]["stack_alignment"] == 0
assert 128 <= len(image) <= profile["memory"]["rom"]["bytes"]
assert image[:8] != b"\0" * 8
assert not any(profile["claims"].values())
digest = hashlib.sha256(image).hexdigest()
print(f"NEBO_REFERENCE_BOARD_SIM_V1_PASS bytes={len(image)} sha256={digest} hardware=false hard_rt=false")
