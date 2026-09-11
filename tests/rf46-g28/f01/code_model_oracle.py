#!/usr/bin/env python3
"""Independent property model for RF46-G28-F01."""
import hashlib
import random

rng = random.Random(0x462801)
accepted = rejected = 0
rows = []
for case in range(50000):
    kind = rng.randrange(0, 7)
    origin = rng.randrange(0, 5)
    span = rng.randrange(0, 5)
    nodes = rng.randrange(0, 70000)
    byte_count = rng.randrange(0, 1100000)
    allowed_kinds = rng.randrange(0, 32)
    effects = rng.randrange(0, 16)
    allowed_effects = rng.randrange(0, 16)
    owner = rng.randrange(0, 5)
    required_owner = rng.randrange(0, 5)
    valid = (
        1 <= kind <= 5 and 1 <= origin <= 3 and span != 0
        and bool(allowed_kinds & (1 << (kind - 1)))
        and not (effects & ~allowed_effects)
        and (required_owner == 0 or owner == required_owner)
        and 0 < nodes <= 65536 and 0 < byte_count <= 1048576
    )
    accepted += int(valid); rejected += int(not valid)
    rows.append(f"{case}:{kind}:{origin}:{span}:{nodes}:{byte_count}:{allowed_kinds}:{effects}:{allowed_effects}:{owner}:{required_owner}:{int(valid)}")
assert accepted and rejected and accepted + rejected == 50000
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF46_G28_F01_ORACLE=PASS cases=50000 accepted={accepted} rejected={rejected} digest={digest}")
