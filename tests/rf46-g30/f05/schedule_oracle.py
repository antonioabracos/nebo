#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463005); nonoverlap=conflict=capacity_fail=0; rows=[]
for _ in range(90000):
    a=r.randrange(0,100); da=r.randrange(1,20); b=r.randrange(0,100); db=r.randrange(1,20); ca=r.randrange(1,8); cb=r.randrange(1,8); cap=r.randrange(1,12)
    overlap=not (a+da<=b or b+db<=a); conflict+=overlap; nonoverlap+=not overlap; capacity_fail+=overlap and ca+cb>cap
    rows.append(f"{a}:{da}:{b}:{db}:{ca}:{cb}:{cap}:{int(overlap)}")
assert nonoverlap and conflict and capacity_fail
print(f"RF46_G30_F05_ORACLE=PASS cases=90000 nonoverlap={nonoverlap} conflicts={conflict} capacity_fail={capacity_fail} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
