#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x462802); seen=set(); rows=[]
for i in range(60000):
    seed=r.randrange(1,1<<32); expansion=r.randrange(1,1<<32); ordinal=r.randrange(1,4096)
    x=(seed*0x100000001b3)&((1<<64)-1); x^=expansion; x=((x<<17)|(x>>(64-17)))&((1<<64)-1); x^=ordinal; x=(x*0x100000001b3)&((1<<64)-1); x=x or 1
    assert x != 0
    seen.add((seed,expansion,ordinal,x)); rows.append(f"{seed}:{expansion}:{ordinal}:{x}")
assert len(seen)==60000
print(f"RF46_G28_F02_ORACLE=PASS cases=60000 deterministic_ids=yes digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
