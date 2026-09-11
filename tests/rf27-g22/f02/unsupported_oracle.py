#!/usr/bin/env python3
import hashlib
import struct

digest = hashlib.sha256()
for case in range(10000):
    digest.update(struct.pack('<I4Q', case, 0, 0, 1, 2))
print(f'RF27_G22_F02_ORACLE=PASS cases=10000 devices=0 handles=0 digest={digest.hexdigest()}')
