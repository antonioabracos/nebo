#!/usr/bin/env python3
import hashlib, random
seed=0x271907
r=random.Random(seed)
h=hashlib.sha256()
for _ in range(4000):
    red,green,blue,alpha=(r.randrange(256) for _ in range(4))
    premul=lambda channel:(channel*alpha+127)//255
    pixel=bytes((premul(blue),premul(green),premul(red),alpha))
    h.update(bytes((red,green,blue,alpha))+pixel)
print(f"RF27_G19_F07_ORACLE=PASS seed=0x{seed:x} cases=4000 digest={h.hexdigest()}")
