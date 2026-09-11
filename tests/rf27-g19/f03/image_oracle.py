#!/usr/bin/env python3
from __future__ import annotations
import hashlib, random
rng=random.Random(0x271903); h=hashlib.sha256(); accepted=rejected=0
for _ in range(5000):
    w=rng.randrange(0,2200); hgt=rng.randrange(0,2200); bpp=rng.choice((1,4))
    stride=rng.randrange(0,70000)
    valid=1<=w<=2048 and 1<=hgt<=2048 and w*bpp<=stride<=65536 and stride*hgt<=16777216
    accepted+=valid; rejected+=not valid
    h.update(bytes((valid,bpp))); h.update(w.to_bytes(2,'little')); h.update(hgt.to_bytes(2,'little')); h.update(stride.to_bytes(4,'little'))
print(f'RF27_G19_F03_ORACLE=PASS seed=0x271903 cases=5000 digest={h.hexdigest()} accepted={accepted} rejected={rejected}')
