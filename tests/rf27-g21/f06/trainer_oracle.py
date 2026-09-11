#!/usr/bin/env python3
import hashlib
import random
import struct

rng = random.Random(0x272106)
digest = hashlib.sha256()
for case in range(5000):
    length = rng.randrange(1, 65)
    patience = rng.randrange(0, 9)
    losses = [rng.uniform(0.01, 8.0) for _ in range(length)]
    counts = [rng.randrange(1, 65) for _ in range(length)]
    best = float('inf')
    stale = 0
    epochs = 0
    samples = 0
    outcome = 0
    for loss, count in zip(losses, counts):
        epochs += 1
        samples += count
        if loss < best:
            best = loss
            stale = 0
        else:
            stale += 1
        if patience and stale >= patience:
            outcome = 1
            break
    digest.update(struct.pack('<IIIIdI', case, patience, epochs, samples, best, outcome))
print(f'RF27_G21_F06_ORACLE=PASS seed=0x272106 cases=5000 digest={digest.hexdigest()}')
