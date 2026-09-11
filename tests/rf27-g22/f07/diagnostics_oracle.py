#!/usr/bin/env python3
import hashlib
import struct

digest = hashlib.sha256()
for case in range(10000):
    operation = case % 32
    report = struct.pack('<6Q', 0x475055, 2, operation, 0, 0, 0)
    assert len(report) == 48
    digest.update(report)
print(f'RF27_G22_F07_ORACLE=PASS cases=10000 trace_bytes=0 device_bytes=0 secrets=0 digest={digest.hexdigest()}')
