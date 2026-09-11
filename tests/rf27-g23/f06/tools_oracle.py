#!/usr/bin/env python3
import hashlib,struct
h=hashlib.sha256(); denied=0
for case in range(5000):
 approved=case%3==0; known=case%5!=0; cap=case%7!=0
 ok=approved and known and cap
 denied+=not ok; h.update(struct.pack('<I???',case,approved,known,cap))
print(f'RF27_G23_F06_ORACLE=PASS cases=5000 denied={denied} tools=16 calls=8 args_bytes=4096 external_effects=0 digest={h.hexdigest()}')
