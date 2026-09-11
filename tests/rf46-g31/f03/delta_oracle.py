#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463103); inserts=removes=updates=moves=0; rows=[]
for _ in range(100000):
    base=[r.randrange(-100,101) for _ in range(r.randrange(1,32))]; before=base[:]; op=r.randrange(4)
    if op==0 and len(base)<64: i=r.randrange(len(base)+1); v=r.randrange(-100,101); base.insert(i,v); base.pop(i); inserts+=1
    elif op==1: i=r.randrange(len(base)); v=base.pop(i); base.insert(i,v); removes+=1
    elif op==2: i=r.randrange(len(base)); old=base[i]; base[i]=r.randrange(-100,101); base[i]=old; updates+=1
    else: i=r.randrange(len(base)); j=r.randrange(len(base)); v=base.pop(i); base.insert(j,v); v=base.pop(j); base.insert(i,v); moves+=1
    assert base==before; rows.append(f"{op}:{len(base)}:{hash(tuple(base))}")
assert inserts and removes and updates and moves
print(f"RF46_G31_F03_ORACLE=PASS cases=100000 insert={inserts} remove={removes} update={updates} move={moves} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
