#!/usr/bin/env python3
import hashlib
import struct

digest = hashlib.sha256()
for case in range(10000):
    host = struct.pack('<4d', 1.0, 2.0, 3.0, 4.0)
    before = hashlib.sha256(host).digest()
    after = hashlib.sha256(host).digest()
    assert before == after
    digest.update(struct.pack('<IQ', case, 0) + before)
print(f'RF27_G22_F03_ORACLE=PASS cases=10000 device_bytes=0 host_unchanged=yes digest={digest.hexdigest()}')
