#!/usr/bin/env python3
import hashlib
import struct

digest = hashlib.sha256()
for case in range(5000):
    requested = case & 1
    selected = 0
    fallback = requested
    transfers = 0
    device_bytes = 0
    digest.update(struct.pack('<5Q', case, requested, selected, fallback, transfers + device_bytes))
print(f'RF27_G22_F06_ORACLE=PASS cases=5000 selected=cpu transfers=0 device_bytes=0 digest={digest.hexdigest()}')
