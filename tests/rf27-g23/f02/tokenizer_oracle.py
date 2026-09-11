#!/usr/bin/env python3
import hashlib

digest = hashlib.sha256()
for case in range(5000):
    data = bytes(((case + i * 17) & 0xff) for i in range(case % 257))
    tokens = list(data)
    assert bytes(tokens) == data
    digest.update(len(tokens).to_bytes(2, 'little') + data)
print(f'RF27_G23_F02_ORACLE=PASS cases=5000 vocab=256 max_tokens=256 roundtrip=bit_exact digest={digest.hexdigest()}')
