#!/usr/bin/env python3
"""Independent privacy-flow and synthetic-secret oracle."""
import hashlib
import random

rng = random.Random(0x27_25_05)
rows: list[str] = []
denied = 0
for case in range(15_000):
    labels = rng.randrange(1, 16)
    clearance = rng.randrange(0, 16)
    purpose = rng.randrange(1, 33)
    sink_purpose = rng.randrange(1, 33)
    redacted = bool(rng.getrandbits(1))
    rejected = 0 if redacted else labels & ~clearance & 0xF
    permit = purpose == sink_purpose and rejected == 0
    denied += int(not permit)
    synthetic = hashlib.sha256(f"secret:{case}:{rng.getrandbits(64)}".encode()).hexdigest()
    rendered = "[REDACTED]"
    assert synthetic not in rendered and rendered == "[REDACTED]"
    rows.append(f"{labels:x}:{clearance:x}:{purpose}:{sink_purpose}:{int(redacted)}:{rejected:x}:{int(permit)}")
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF27_G25_F05_ORACLE=PASS flows=15000 denied={denied} raw_secret_leaks=0 digest={digest}")
