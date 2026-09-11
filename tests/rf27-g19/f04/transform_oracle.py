#!/usr/bin/env python3
from __future__ import annotations
import hashlib, random
rng=random.Random(0x271904); digest=hashlib.sha256()
def bilinear(p,w,src_h,dw,dh,x,y):
    if dw==1: x0=x1=0; wx=0
    else:
        q,r=divmod(x*(w-1),dw-1); x0=q; x1=min(q+1,w-1); wx=(r<<16)//(dw-1)
    if dh==1: y0=y1=0; wy=0
    else:
        q,r=divmod(y*(src_h-1),dh-1); y0=q; y1=min(q+1,src_h-1); wy=(r<<16)//(dh-1)
    out=[]
    for c in range(4):
        a=(p[y0][x0][c]*(65536-wx)+p[y0][x1][c]*wx+32768)>>16
        b=(p[y1][x0][c]*(65536-wx)+p[y1][x1][c]*wx+32768)>>16
        out.append((a*(65536-wy)+b*wy+32768)>>16)
    return tuple(out)
for _ in range(3000):
    w=src_h=2; p=[[tuple(rng.randrange(256) for _ in range(4)) for _ in range(w)] for _ in range(src_h)]
    dw=rng.randrange(1,9); dh=rng.randrange(1,9)
    for x,y in ((0,0),(dw-1,dh-1),(dw//2,dh//2)):
        digest.update(bytes(bilinear(p,w,src_h,dw,dh,x,y)))
print(f'RF27_G19_F04_ORACLE=PASS seed=0x271904 cases=3000 digest={digest.hexdigest()}')
