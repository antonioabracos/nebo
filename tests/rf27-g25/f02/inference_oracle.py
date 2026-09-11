#!/usr/bin/env python3
"""Independent bounded graph/fixed-point oracle for RF27-G25-F02."""
import hashlib
import random

MASK = (1 << 14) - 1
rng = random.Random(0x27_25_02)
rows: list[str] = []
cyclic = 0

for case in range(5_000):
    count = rng.randrange(1, 33)
    direct = [rng.randrange(MASK + 1) & rng.randrange(MASK + 1) for _ in range(count)]
    edges: list[list[int]] = []
    for node in range(count):
        choices = [rng.randrange(count) for _ in range(rng.randrange(0, 5))]
        edges.append(choices)
        cyclic += int(node in choices)
    inferred = direct[:]
    passes = 0
    while True:
        passes += 1
        changed = False
        for node in range(count):
            joined = inferred[node]
            for callee in edges[node]:
                joined |= inferred[callee]
            if joined != inferred[node]:
                inferred[node] = joined
                changed = True
        if not changed:
            break
        assert passes <= count
    assert all((value & ~MASK) == 0 for value in inferred)
    assert all((direct[i] & ~inferred[i]) == 0 for i in range(count))
    assert all((inferred[c] & ~inferred[n]) == 0 for n in range(count) for c in edges[n])
    declared = inferred[:]
    if case % 7 == 0 and inferred[0]:
        lowest = inferred[0] & -inferred[0]
        declared[0] ^= lowest
        assert inferred[0] & ~declared[0] == lowest
    rows.append(f"{count}:{passes}:" + ",".join(f"{value:04x}" for value in inferred))

digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(
    "RF27_G25_F02_ORACLE=PASS "
    f"graphs=5000 self_cycles={cyclic} max_nodes=32 digest={digest}"
)
