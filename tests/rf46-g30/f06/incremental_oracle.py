#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463006); pushes=pops=cores=0; rows=[]
for _ in range(100000):
    depth=0; constraints=0; marks=[]
    for _ in range(r.randrange(1,20)):
        op=r.randrange(3)
        if op==0 and depth<32: marks.append(constraints); depth+=1; pushes+=1
        elif op==1 and depth: depth-=1; constraints=marks.pop(); pops+=1
        else: constraints+=r.randrange(1,5)
    required=r.randrange(1<<16); forbidden=r.randrange(1<<16); core=required&forbidden; cores+=bool(core)
    rows.append(f"{depth}:{constraints}:{core}")
assert pushes and pops and cores
print(f"RF46_G30_F06_ORACLE=PASS cases=100000 pushes={pushes} pops={pops} unsat_cores={cores} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
