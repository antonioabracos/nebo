#!/usr/bin/env python3
import hashlib
import math
import random
import struct

rng = random.Random(0x272105)
digest = hashlib.sha256()
for case in range(5000):
    count = rng.randrange(1, 33)
    params = [rng.uniform(-4.0, 4.0) for _ in range(count)]
    grads = [rng.uniform(-1.0, 1.0) for _ in range(count)]
    lr = rng.uniform(0.0001, 0.1)
    momentum = rng.uniform(0.0, 0.99)
    velocity = [rng.uniform(-0.2, 0.2) for _ in range(count)]
    sgd = [p - lr * g for p, g in zip(params, grads)]
    next_velocity = [momentum * v + g for v, g in zip(velocity, grads)]
    momentum_params = [p - lr * v for p, v in zip(params, next_velocity)]
    step = rng.randrange(1, 10001)
    linear = lr * (1.0 - step / 10000.0)
    digest.update(struct.pack('<II2d', case, count, lr, linear))
    for series in (sgd, next_velocity, momentum_params):
        digest.update(b''.join(struct.pack('<d', x) for x in series))
    assert all(math.isfinite(x) for x in sgd + next_velocity + momentum_params)
print(f'RF27_G21_F05_ORACLE=PASS seed=0x272105 cases=5000 digest={digest.hexdigest()}')
