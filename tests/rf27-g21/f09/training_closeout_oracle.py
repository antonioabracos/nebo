#!/usr/bin/env python3
import hashlib
import random
import struct

rng = random.Random(0x272109)
digest = hashlib.sha256()
for case in range(3000):
    parameter = rng.uniform(-4.0, 4.0)
    rate = rng.uniform(0.01, 0.2)
    losses = []
    for _ in range(32):
        losses.append(parameter * parameter)
        parameter -= rate * (2.0 * parameter)
    final_loss = parameter * parameter
    assert final_loss < losses[0]
    assert all(b <= a for a, b in zip(losses, losses[1:]))
    digest.update(struct.pack('<I3d', case, rate, losses[0], final_loss))
print(f'RF27_G21_F09_ORACLE=PASS seed=0x272109 cases=3000 bounded_convergence=yes digest={digest.hexdigest()}')
