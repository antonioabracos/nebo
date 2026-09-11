#!/usr/bin/env python3
"""Independent bounded target-registry oracle."""
import hashlib
import random
import sys

sys.dont_write_bytecode = True
rng = random.Random(0x27_27_02)
known_x86 = 1
registry: dict[int, tuple[int, int]] = {}
accepted = fake = missing = duplicate = limit = version = 0
rows: list[str] = []
for case in range(30_000):
    triple = rng.randrange(0, 32)
    maturity = rng.randrange(0, 5)
    fields = rng.randrange(0, 64)
    components = rng.randrange(0, 32)
    abi_version = rng.randrange(0, 3)
    status = "ok"
    if not triple or not maturity or maturity > 3 or fields != 63:
        status = "missing"
        missing += 1
    elif abi_version != 1:
        status = "version"
        version += 1
    elif maturity == 3 and (triple != known_x86 or components != 31):
        status = "fake"
        fake += 1
    elif triple in registry:
        status = "duplicate"
        duplicate += 1
    elif len(registry) == 8:
        status = "limit"
        limit += 1
    else:
        registry[triple] = (maturity, components)
        accepted += 1
    rows.append(f"{case}:{triple}:{maturity}:{fields}:{components}:{abi_version}:{status}:{len(registry)}")
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
certified = sum(maturity == 3 for maturity, _ in registry.values())
print(f"RF27_G27_F02_ORACLE=PASS cases=30000 accepted={accepted} fake={fake} missing={missing} duplicate={duplicate} limit={limit} version={version} targets={len(registry)} certified={certified} digest={digest}")
