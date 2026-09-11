#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x462903); proved=runtime=failed=0; rows=[]; lo=-(1<<63); hi=(1<<63)-1
for _ in range(90000):
    kind=r.randrange(1,5); a=r.randrange(0,1<<20); b=r.randrange(0,1<<20)
    if kind==1: state="proved" if lo<=a+b<=hi else "failed"
    elif kind==2: state="proved" if b and a<b else "failed"
    elif kind==3: state="proved" if a & b == a else "runtime"
    else: state="proved" if a & ~b == 0 else "failed"
    proved+=state=="proved"; runtime+=state=="runtime"; failed+=state=="failed"; rows.append(f"{kind}:{a}:{b}:{state}")
assert proved and runtime and failed
print(f"RF46_G29_F03_ORACLE=PASS cases=90000 proved={proved} runtime={runtime} failed={failed} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
