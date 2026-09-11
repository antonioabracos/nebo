#!/usr/bin/env python3
import hashlib, random
r = random.Random(0x462901); accepted = runtime = rejected = 0; rows = []
for _ in range(60000):
    kind = r.randrange(0, 5); modifies = r.randrange(0, 70); proof = r.randrange(1, 4); policy = r.randrange(1, 3); condition = r.randrange(2)
    valid = 1 <= kind <= 3 and modifies <= 64
    action = "invalid"
    if valid and proof == 1: action = "proved"; accepted += 1
    elif valid and proof == 2 and policy == 2 and condition: action = "runtime"; runtime += 1
    else: rejected += 1
    rows.append(f"{kind}:{modifies}:{proof}:{policy}:{condition}:{action}")
assert accepted and runtime and rejected
print(f"RF46_G29_F01_ORACLE=PASS cases=60000 proved={accepted} runtime={runtime} rejected={rejected} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
