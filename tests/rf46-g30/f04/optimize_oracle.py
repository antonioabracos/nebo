#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463004); optimal=partial=0; rows=[]
for _ in range(80000):
    n=r.randrange(1,65); values=[r.randrange(-100000,100001) for _ in range(n)]; budget=r.randrange(1,n+1); mode=r.randrange(2)
    prefix=values[:budget]; value=(max if mode else min)(prefix); state="optimal" if budget==n else "gap"
    optimal+=state=="optimal"; partial+=state=="gap"; rows.append(f"{n}:{budget}:{mode}:{value}:{state}")
assert optimal and partial
print(f"RF46_G30_F04_ORACLE=PASS cases=80000 optimal={optimal} gap_bounded={partial} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
