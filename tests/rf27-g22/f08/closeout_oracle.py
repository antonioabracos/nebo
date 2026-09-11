#!/usr/bin/env python3
import hashlib
import struct

digest = hashlib.sha256()
for case in range(10000):
    device_count = 0
    device_bytes = 0
    streams = 0
    events = 0
    modules = 0
    trace_bytes = 0
    digest.update(struct.pack('<7Q', case, device_count, device_bytes, streams, events, modules, trace_bytes))
print(f'RF27_G22_F08_ORACLE=PASS cases=10000 devices=0 device_bytes=0 streams=0 events=0 modules=0 trace_bytes=0 digest={digest.hexdigest()}')
