#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x462902); yes=no=0; rows=[]
for _ in range(70000):
    a=r.randrange(-100000,100001); b=r.randrange(-100000,100001); lo=min(a,b); hi=max(a,b); v=r.randrange(-150000,150001)
    accepted=lo<=v<=hi; yes+=accepted; no+=not accepted
    rows.append(f"{lo}:{hi}:{v}:{int(accepted)}")
assert yes and no
print(f"RF46_G29_F02_ORACLE=PASS cases=70000 accepted={yes} rejected={no} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
