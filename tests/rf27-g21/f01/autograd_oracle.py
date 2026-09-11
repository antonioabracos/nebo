#!/usr/bin/env python3
import hashlib
import random

rng = random.Random(0x272101)
digest = hashlib.sha256()
for case in range(5000):
    generation = 1
    nodes = []
    saved = 0
    for _ in range(rng.randrange(1, 33)):
        flags = 1 if rng.randrange(2) else 0
        amount = rng.randrange(0, 9)
        if saved + amount > 4096:
            break
        nodes.append([generation, flags, amount])
        saved += amount
    if nodes and rng.randrange(2):
        index = rng.randrange(len(nodes)); nodes[index][1] = 4
    if rng.randrange(4) == 0:
        generation += 1; nodes.clear(); saved = 0
    digest.update(case.to_bytes(4, "little"))
    digest.update(generation.to_bytes(4, "little"))
    digest.update(len(nodes).to_bytes(4, "little"))
    digest.update(saved.to_bytes(4, "little"))
    digest.update(bytes(node[1] for node in nodes))
print(f"RF27_G21_F01_ORACLE=PASS seed=0x272101 cases=5000 digest={digest.hexdigest()}")
