#!/usr/bin/env python3
"""Independent Python-int oracle for RF46-G35-F01."""
import math
import random

rng = random.Random(0x463501)
for _ in range(512):
    a = rng.randrange(0, 1 << 256)
    b = rng.randrange(0, 1 << 128)
    d = rng.randrange(1, 1 << 32)
    assert divmod(a + b, d)[0] * d + divmod(a + b, d)[1] == a + b
    assert math.gcd(a, b) == math.gcd(b, a)
    assert a.bit_length() <= 256
print("RF46_G35_F01_ORACLE_PASS vectors=512 bits=256 seed=0x463501")
