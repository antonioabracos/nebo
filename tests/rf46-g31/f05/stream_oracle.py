#!/usr/bin/env python3
import collections, hashlib, random
r=random.Random(0x463105); pushed=popped=dropped=rejected=0; rows=[]
for _ in range(100000):
    cap=r.randrange(1,17); policy=r.randrange(2); q=collections.deque()
    for _ in range(r.randrange(1,40)):
        if r.randrange(3):
            v=r.randrange(-100,101)
            if len(q)==cap:
                if policy: q.popleft(); dropped+=1
                else: rejected+=1; continue
            q.append(v); pushed+=1
        elif q: q.popleft(); popped+=1
    rows.append(f"{cap}:{policy}:{list(q)}:{sum(q)}")
assert pushed and popped and dropped and rejected
print(f"RF46_G31_F05_ORACLE=PASS cases=100000 pushed={pushed} popped={popped} dropped={dropped} backpressure={rejected} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
