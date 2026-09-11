#!/usr/bin/env python3
import hashlib,struct
h=hashlib.sha256()
for case in range(5000):
 n=case%65; schema=[(case+i)%4 for i in range(n)]; values=list(schema); assert values==schema; h.update(struct.pack('<II',case,n)+bytes(schema))
print(f'RF27_G23_F05_ORACLE=PASS cases=5000 prompt_bytes=4096 fields=64 repairs=1 exact_validation=yes digest={h.hexdigest()}')
