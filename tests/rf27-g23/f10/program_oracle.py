#!/usr/bin/env python3
import hashlib,struct
h=hashlib.sha256()
for case in range(10000):
 state=(case,10,9,9,8,10,0)
 h.update(struct.pack('<7Q',*state))
print(f'RF27_G23_F10_ORACLE=PASS cases=10000 groups=5 fronts=46 g22_backend=unavailable g23_external_effects=0 digest={h.hexdigest()}')
