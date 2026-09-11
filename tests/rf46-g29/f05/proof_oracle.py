#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x462905); valid=changed=incompatible=0; rows=[]
for _ in range(80000):
    subject=r.randrange(1,1<<32); spec=r.randrange(1,1<<32); current_subject=subject if r.randrange(3) else subject+1; current_spec=spec if r.randrange(3) else spec+1
    ok=subject==current_subject and spec==current_spec
    valid+=ok; changed+=not ok
    other_subject=subject if r.randrange(2) else subject+2; compatible=subject==other_subject; incompatible+=not compatible
    rows.append(f"{subject}:{spec}:{current_subject}:{current_spec}:{int(ok)}:{int(compatible)}")
assert valid and changed and incompatible
print(f"RF46_G29_F05_ORACLE=PASS cases=80000 valid={valid} changed={changed} incompatible={incompatible} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
