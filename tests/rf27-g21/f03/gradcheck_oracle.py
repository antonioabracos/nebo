#!/usr/bin/env python3
import hashlib
import math
import random
import struct

rng = random.Random(0x272103)
digest = hashlib.sha256()
for case in range(5000):
    count = rng.randrange(1, 33)
    step = rng.choice((0.0001, 0.0002, 0.0005, 0.001))
    gradients = []
    numeric = []
    for _ in range(count):
        a = rng.uniform(-3.0, 3.0)
        b = rng.uniform(-3.0, 3.0)
        c = rng.uniform(-3.0, 3.0)
        x = rng.uniform(-3.0, 3.0)
        analytic = 2.0 * a * x + b
        plus = a * (x + step) ** 2 + b * (x + step) + c
        minus = a * (x - step) ** 2 + b * (x - step) + c
        central = (plus - minus) / (2.0 * step)
        assert abs(analytic - central) <= 1.0e-8
        gradients.append(analytic)
        numeric.append(central)
    value_limit = rng.uniform(0.01, 3.0)
    value_clipped = [max(-value_limit, min(value_limit, x)) for x in gradients]
    norm_limit = rng.uniform(0.01, 5.0)
    norm = math.sqrt(sum(x * x for x in gradients))
    scale = min(1.0, norm_limit / norm) if norm else 1.0
    norm_clipped = [x * scale for x in gradients]
    digest.update(struct.pack('<II', case, count))
    for series in (numeric, value_clipped, norm_clipped, list(gradients)):
        digest.update(b''.join(struct.pack('<d', x) for x in series))
print(f'RF27_G21_F03_ORACLE=PASS seed=0x272103 cases=5000 digest={digest.hexdigest()}')
