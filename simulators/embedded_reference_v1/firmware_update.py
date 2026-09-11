#!/usr/bin/env python3
"""Failure-atomic A/B update model for the simulator-only reference board."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--manifest", type=Path, required=True)
args = parser.parse_args()
manifest = json.loads(args.manifest.read_text(encoding="utf-8"))

assert manifest["schema"] == "NEBO_FIRMWARE_MANIFEST-v1"
assert manifest["target_id"] == "NEBO_REFERENCE_BOARD_SIM_V1"
assert manifest["slots"] == 2
assert manifest["rollback_counter"] == manifest["version"]
assert manifest["signature"] == "NOT_PRESENT_SIMULATOR_ONLY"

steps = ("write_inactive", "verify_hash", "raise_counter", "activate")

def simulate(power_cut: int | None) -> tuple[str, int, bool]:
    active = "A"
    counter = 1
    verified_b = False
    for index, step in enumerate(steps):
        if power_cut == index:
            break
        if step == "write_inactive":
            pass
        elif step == "verify_hash":
            verified_b = True
        elif step == "raise_counter":
            assert verified_b
            counter = 2
        else:
            assert verified_b and counter == 2
            active = "B"
    return active, counter, verified_b

states = [simulate(cut) for cut in range(len(steps) + 1)]
assert [state[0] for state in states] == ["A", "A", "A", "A", "B"]
assert all(active == "A" or (counter == 2 and verified) for active, counter, verified in states)
digest = hashlib.sha256(json.dumps(states, separators=(",", ":")).encode()).hexdigest()
print(f"RF46_G38_F07_UPDATE_PASS cuts=5 active_before_commit=A active_after_commit=B digest={digest} secure_boot=false")
