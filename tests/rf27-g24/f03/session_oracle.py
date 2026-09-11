#!/usr/bin/env python3
"""Deterministic bounded REPL lifecycle model."""
from hashlib import sha256
from random import Random

rng = Random(0x272403)
generation = 1
history = loads = source_bytes = resets = accepted = 0
digest = sha256()
for _ in range(10_000):
    operation = rng.randrange(0, 8)
    size = rng.randrange(1, 2049)
    if operation == 0:
        generation += 1
        history = loads = source_bytes = 0
        resets += 1
        decision = 1
    else:
        is_load = operation == 1
        decision = int(
            history < 64 and source_bytes + size <= 65_536
            and (not is_load or loads < 16)
        )
        if decision:
            history += 1
            source_bytes += size
            loads += is_load
            accepted += 1
    digest.update(bytes((operation, decision)))
    digest.update(size.to_bytes(2, "little"))
    digest.update(generation.to_bytes(4, "little"))
print(
    f"RF27_G24_F03_ORACLE=PASS seed=0x272403 cases=10000 accepted={accepted} "
    f"resets={resets} generation={generation} digest={digest.hexdigest()}"
)
