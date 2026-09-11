#!/usr/bin/env python3
"""Independent deterministic RF27 test-plan admission oracle."""
import hashlib
import random
import sys

sys.dont_write_bytecode = True
rng = random.Random(0x27_24_10)
accepted = traversal = diagnostic = fuzz_limit = drift = limit = 0
rows: list[str] = []
for case in range(30_000):
    kind = rng.randrange(0, 6)
    path_hash = rng.randrange(0, 128)
    expected = rng.randrange(0, 4)
    fuzz_cases = rng.randrange(0, 5000) if kind == 3 else rng.randrange(0, 2)
    flags = rng.randrange(0, 5)
    snapshot_expected = rng.randrange(0, 32)
    snapshot_actual = snapshot_expected if rng.randrange(4) else rng.randrange(0, 32)
    status = "ok"
    if kind < 1 or kind > 4 or path_hash == 0:
        status = "invalid"
        diagnostic += 1
    elif expected > 1:
        status = "diagnostic"
        diagnostic += 1
    elif flags != 3:
        status = "traversal"
        traversal += 1
    elif kind == 3 and not 1 <= fuzz_cases <= 4096:
        status = "fuzz-limit"
        fuzz_limit += 1
    elif kind != 3 and fuzz_cases != 0:
        status = "invalid"
        diagnostic += 1
    elif kind == 4 and snapshot_expected != snapshot_actual:
        status = "snapshot-drift"
        drift += 1
    elif accepted == 1024:
        status = "limit"
        limit += 1
    else:
        accepted += 1
    rows.append(f"{case}:{kind}:{path_hash}:{expected}:{fuzz_cases}:{flags}:{snapshot_expected}:{snapshot_actual}:{status}:{accepted}")
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF27_G24_F10_ORACLE=PASS plans=30000 accepted={accepted} traversal={traversal} diagnostic={diagnostic} fuzz_limit={fuzz_limit} drift={drift} capacity_limit={limit} digest={digest}")
