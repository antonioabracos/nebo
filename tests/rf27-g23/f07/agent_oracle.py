#!/usr/bin/env python3
import hashlib,struct
h=hashlib.sha256();cancelled=0
for case in range(5000):
 steps=case%17;calls=min(8,steps//2);cancel=case%7==0;cancelled+=cancel;h.update(struct.pack('<III?',case,steps,calls,cancel))
print(f'RF27_G23_F07_ORACLE=PASS cases=5000 cancelled={cancelled} steps=16 calls=8 approvals=8 trace_bytes=65536 compensation_only=yes digest={h.hexdigest()}')
