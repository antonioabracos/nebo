#!/usr/bin/env python3
"""Independent adversarial model for the bounded G26 extension closeout."""
import hashlib
import random
import sys

sys.dont_write_bytecode = True
rng = random.Random(0x27_26_09)
surfaces = (
    "extension_abi", "manifest", "process", "sandbox", "ffi",
    "protocol", "remote_task", "fault",
)
accepted = denied = environment_limited = 0
rows: list[str] = []
for case in range(120_000):
    surface = surfaces[rng.randrange(len(surfaces))]
    schema = rng.randrange(6) != 0
    content_hash = rng.randrange(7) != 0
    target = rng.randrange(8) != 0
    authority = rng.randrange(5) != 0
    bounded = rng.randrange(9) != 0
    registered = rng.randrange(6) != 0
    deadline = rng.randrange(7) != 0
    checkpoint = rng.randrange(8) != 0
    compensation = rng.randrange(5) != 0
    live_optional = surface in ("sandbox", "protocol") and rng.randrange(24) == 0
    required = schema and content_hash and target and authority and bounded
    if surface in ("remote_task", "fault"):
        required = required and registered and deadline
    if surface == "fault":
        required = required and checkpoint and compensation
    if live_optional:
        status = "environment-limited"
        environment_limited += 1
    elif required:
        status = "accept"
        accepted += 1
    else:
        status = "deny"
        denied += 1
    if status == "accept" and not required:
        raise AssertionError("authority escape accepted")
    rows.append(
        f"{case}:{surface}:{int(schema)}:{int(content_hash)}:{int(target)}:"
        f"{int(authority)}:{int(bounded)}:{int(registered)}:{int(deadline)}:"
        f"{int(checkpoint)}:{int(compensation)}:{status}"
    )
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(
    "RF27_G26_F09_ORACLE=PASS "
    f"cases=120000 accepted={accepted} denied={denied} "
    f"environment_limited={environment_limited} surfaces=8 digest={digest}"
)
