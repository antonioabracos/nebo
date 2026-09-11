#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x462906); original=minimized=invalid=0; rows=[]
for _ in range(100000):
    n=r.randrange(2,33); trace=[r.randrange(16)]
    for _ in range(n-1): trace.append(trace[-1] if r.randrange(3)==0 else r.randrange(16))
    small=[x for i,x in enumerate(trace) if i==0 or x!=trace[i-1]]
    original+=len(trace); minimized+=len(small); invalid+=any(a==b for a,b in zip(small,small[1:])); rows.append(f"{','.join(map(str,trace))}:{','.join(map(str,small))}")
assert minimized<original and invalid==0
print(f"RF46_G29_F06_ORACLE=PASS cases=100000 original_steps={original} minimized_steps={minimized} consecutive_duplicates={invalid} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
