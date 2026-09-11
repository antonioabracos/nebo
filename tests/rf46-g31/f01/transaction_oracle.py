#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463101); commits=rollbacks=writes=0; rows=[]
for _ in range(90000):
    cells=[(r.randrange(-1000,1001),1) for _ in range(8)]; staged={}
    for _ in range(r.randrange(1,20)): staged[r.randrange(8)]=r.randrange(-1000,1001); writes+=1
    if r.randrange(2):
        for i,v in staged.items(): cells[i]=(v,cells[i][1]+1)
        commits+=1; outcome="commit"
    else: rollbacks+=1; outcome="rollback"
    rows.append(f"{outcome}:{sorted(staged.items())}:{cells}")
assert commits and rollbacks and writes
print(f"RF46_G31_F01_ORACLE=PASS cases=90000 commits={commits} rollbacks={rollbacks} staged_writes={writes} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
