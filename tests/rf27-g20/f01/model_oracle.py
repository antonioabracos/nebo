#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x272001); h=hashlib.sha256(); valid=0
for _ in range(5000):
    n=r.randint(1,70); edges=[]
    for _ in range(r.randint(0,140)):
        a=r.randrange(n); b=r.randrange(n); edges.append((a,b))
    edges.sort()
    ok=n<=64 and len(edges)<=128 and all(a<b<n for a,b in edges) and len(edges)==len(set(edges))
    valid+=ok; h.update(f"{n}:{len(edges)}:{int(ok)}\n".encode())
print(f"RF27_G20_F01_ORACLE=PASS seed=0x272001 cases=5000 valid={valid} invalid={5000-valid} digest={h.hexdigest()}")
