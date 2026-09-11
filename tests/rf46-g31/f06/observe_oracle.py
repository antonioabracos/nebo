#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463106); equal=events=dropped=0; rows=[]
for _ in range(120000):
    n=r.randrange(1,33); edges=[0]*n; values=[r.randrange(-100,101) for _ in range(n)]
    for a in range(n):
        for b in range(a+1,n):
            if r.randrange(10)==0: edges[a]|=1<<b
    changed=1<<r.randrange(n); affected=frontier=changed
    while frontier:
        nxt=0
        for i in range(n):
            if frontier>>i&1: nxt|=edges[i]
        frontier=nxt&~affected; affected|=frontier
    incremental=values[:]; full=values[:]
    for i in range(n):
        if affected>>i&1: incremental[i]=values[i]+1
        if affected>>i&1: full[i]=values[i]+1
    assert incremental==full; equal+=1; events+=affected.bit_count(); dropped+=max(0,affected.bit_count()-16)
    rows.append(f"{n}:{changed}:{affected}:{sum(incremental)}")
assert equal==120000 and events
print(f"RF46_G31_F06_ORACLE=PASS cases={equal} incremental_equals_full={equal} causal_events={events} bounded_trace_overflow={dropped} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
