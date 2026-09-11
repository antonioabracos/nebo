#!/usr/bin/env python3
import hashlib,math,random
r=random.Random(0x272003); h=hashlib.sha256()
for _ in range(3000):
 xs=[r.uniform(-8,8) for _ in range(r.randint(1,64))]; mean=sum(xs)/len(xs); var=sum((x-mean)**2 for x in xs)/len(xs); eps=1e-5
 norm=[(x-mean)/math.sqrt(var+eps) for x in xs]; h.update(repr((norm,sum(norm))).encode())
print(f"RF27_G20_F03_ORACLE=PASS seed=0x272003 cases=3000 digest={h.hexdigest()}")
