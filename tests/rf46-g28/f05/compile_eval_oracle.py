#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x462805); ok=overflow=0; rows=[]; lo=-(1<<63); hi=(1<<63)-1
for i in range(80000):
 a=r.randrange(lo,hi+1); b=r.randrange(lo,hi+1); op=r.randrange(1,5)
 value={1:a+b,2:a-b,3:a*b,4:int(a==b)}[op]; valid=lo<=value<=hi
 ok+=valid; overflow+=not valid; rows.append(f"{op}:{a}:{b}:{value if valid else 'overflow'}")
assert ok and overflow
print(f"RF46_G28_F05_ORACLE=PASS cases=80000 valid={ok} overflow={overflow} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
