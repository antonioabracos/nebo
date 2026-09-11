#!/usr/bin/env python3
import hashlib
import random
import struct

rng = random.Random(0x272107)
mask = (1 << 64) - 1
digest = hashlib.sha256()
for case in range(5000):
    size = rng.randrange(1, 257)
    seed = rng.randrange(1, 1 << 64)
    state = seed
    permutation = list(range(size))
    for index in range(size - 1, 0, -1):
        state ^= (state << 13) & mask
        state ^= state >> 7
        state ^= (state << 17) & mask
        state &= mask
        selected = state % (index + 1)
        permutation[index], permutation[selected] = permutation[selected], permutation[index]
    numerator = rng.randrange(1, 100)
    denominator = rng.randrange(numerator + 1, 101)
    train = size * numerator // denominator
    digest.update(struct.pack('<IIQQ', case, size, state, train))
    digest.update(b''.join(struct.pack('<Q', x) for x in permutation))
    assert sorted(permutation) == list(range(size))
print(f'RF27_G21_F07_ORACLE=PASS seed=0x272107 cases=5000 digest={digest.hexdigest()}')
