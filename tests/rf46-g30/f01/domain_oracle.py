#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463001); valid=invalid=0; rows=[]
for _ in range(80000):
    kind=r.randrange(1,6); lo=r.randrange(-1000,1001); hi=r.randrange(-1000,1001); count=r.randrange(0,300)
    ok=kind<=4 and lo<=hi and 1<=count<=256 and (kind!=2 or (lo,hi,count)==(0,1,2))
    valid+=ok; invalid+=not ok; rows.append(f"{kind}:{lo}:{hi}:{count}:{int(ok)}")
assert valid and invalid
print(f"RF46_G30_F01_ORACLE=PASS cases=80000 valid={valid} invalid={invalid} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
