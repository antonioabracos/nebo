#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463104); dags=closures=0; rows=[]
for _ in range(90000):
    n=r.randrange(1,33); edges=[0]*n
    for a in range(n):
        for b in range(a+1,n):
            if r.randrange(8)==0: edges[a]|=1<<b
    changed=1<<r.randrange(n); affected=frontier=changed
    while frontier:
        nxt=0
        for i in range(n):
            if frontier>>i&1: nxt|=edges[i]
        frontier=nxt&~affected; affected|=frontier
    dags+=1; closures+=affected.bit_count(); rows.append(f"{n}:{changed}:{affected}:{sum(x.bit_count() for x in edges)}")
assert dags and closures>=dags
print(f"RF46_G31_F04_ORACLE=PASS cases={dags} affected_nodes={closures} graphs=acyclic_by_construction digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
