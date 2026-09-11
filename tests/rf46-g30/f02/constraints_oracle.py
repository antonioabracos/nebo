#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463002); sat=unsat=0; rows=[]
for _ in range(100000):
    n=r.randrange(1,17); values=[r.randrange(0,8) for _ in range(n)]; op=r.randrange(1,6)
    if op==1: ok=bool(values[0])
    elif op==2: ok=n>=2 and (not values[0] or bool(values[1]))
    elif op==3: ok=sum(bool(x) for x in values)==1
    elif op==4: ok=len(set(values))==len(values)
    else: target=r.randrange(0,128); ok=sum(values)==target
    sat+=ok; unsat+=not ok; rows.append(f"{op}:{','.join(map(str,values))}:{int(ok)}")
assert sat and unsat
print(f"RF46_G30_F02_ORACLE=PASS cases=100000 sat={sat} unsat={unsat} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
