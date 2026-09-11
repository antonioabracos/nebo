#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x462806); accepted=rejected=0; rows=[]
for i in range(100000):
 arity=r.randrange(0,20); depth=r.randrange(0,40); nodes=r.randrange(0,70000); size=r.randrange(0,1100000)
 ok=arity<=16 and 1<=depth<=32 and nodes<=65536 and size<=1048576
 accepted+=ok; rejected+=not ok; rows.append(f"{arity}:{depth}:{nodes}:{size}:{int(ok)}")
assert accepted and rejected
print(f"RF46_G28_F06_ORACLE=PASS cases=100000 accepted={accepted} rejected={rejected} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
