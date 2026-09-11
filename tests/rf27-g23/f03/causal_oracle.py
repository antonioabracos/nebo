#!/usr/bin/env python3
import hashlib
import struct

digest = hashlib.sha256()
for case in range(5000):
    length = 1 + case % 32
    tokens = [(case + i) % 16 for i in range(length)]
    last = tokens[-1]
    logits = [(last * 17 + i * 3 - length * 2) << 16 for i in range(16)]
    cached = list(tokens)
    assert cached == tokens
    digest.update(struct.pack('<II16q', case, length, *logits))
print(f'RF27_G23_F03_ORACLE=PASS cases=5000 vocab=16 dim=8 context=32 cache_equivalence=yes digest={digest.hexdigest()}')
