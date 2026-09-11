#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463102); incremental=full=0; rows=[]
for _ in range(100000):
    n=r.randrange(1,33); values=[r.randrange(-1000,1001) for _ in range(n)]; mask=r.randrange(1,1<<n); changed=r.randrange(n); updated=values[:]; updated[changed]+=r.randrange(-10,11)
    before=sum(v for i,v in enumerate(values) if mask>>i&1); after=sum(v for i,v in enumerate(updated) if mask>>i&1)
    if mask>>changed&1: incremental+=1
    else: full+=1; assert before==after
    rows.append(f"{n}:{mask}:{changed}:{before}:{after}")
assert incremental and full
print(f"RF46_G31_F02_ORACLE=PASS cases=100000 affected={incremental} unaffected={full} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
