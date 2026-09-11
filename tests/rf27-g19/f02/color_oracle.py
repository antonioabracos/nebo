#!/usr/bin/env python3
from __future__ import annotations
import hashlib, random
def linear(c: int) -> int:
    s=c/255.0
    v=s/12.92 if s<=0.04045 else ((s+0.055)/1.055)**2.4
    return round(v*65535)
def gray(r: int,g: int,b: int) -> int:
    return (13933*r+46871*g+4732*b+32768)>>16
table=[linear(i) for i in range(256)]
assert table[0]==0 and table[255]==65535 and all(a<b for a,b in zip(table,table[1:]))
assert all(min(range(256),key=lambda i:(abs(table[i]-table[c]),i))==c for c in range(256))
rng=random.Random(0x271902)
h=hashlib.sha256(); cases=5000
for _ in range(cases):
    r,g,b,a=(rng.randrange(256) for _ in range(4))
    packed=r|(g<<8)|(b<<16)|(a<<24)
    record=(packed,gray(r,g,b),table[r],table[g],table[b])
    h.update(b''.join(x.to_bytes(4,'little') for x in record))
print(f'RF27_G19_F02_ORACLE=PASS seed=0x271902 cases={cases} digest={h.hexdigest()} linear128={table[128]} gray255={gray(255,255,255)}')
