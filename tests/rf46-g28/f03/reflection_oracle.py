#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x462803); valid=invalid=0; rows=[]
for i in range(50000):
 size=r.randrange(0,257); align=1<<r.randrange(0,7); count=r.randrange(0,70); off=0
 fields=[]
 for _ in range(count):
  width=r.randrange(0,17); fields.append((off,width)); off+=width
 ok=count<=64 and align<=64 and all(o+w<=size for o,w in fields)
 valid+=ok; invalid+=not ok; rows.append(f"{size}:{align}:{count}:{off}:{int(ok)}")
assert valid and invalid
print(f"RF46_G28_F03_ORACLE=PASS cases=50000 valid={valid} invalid={invalid} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
