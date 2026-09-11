#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x463003); sat=unsat=timeout=0; rows=[]
for _ in range(90000):
    n=r.randrange(1,13); mask=(1<<n)-1; required=r.randrange(mask+1); forbidden=r.randrange(mask+1); budget=r.randrange(1,1<<min(n,8))
    if required & forbidden: state="unsat"; answer=None
    else:
        answer=next((x for x in range(min(1<<n,budget)) if x&required==required and not x&forbidden),None)
        state="sat" if answer is not None else ("timeout" if budget < 1<<n else "unsat")
    sat+=state=="sat"; unsat+=state=="unsat"; timeout+=state=="timeout"; rows.append(f"{n}:{required}:{forbidden}:{budget}:{state}:{answer}")
assert sat and unsat and timeout
print(f"RF46_G30_F03_ORACLE=PASS cases=90000 sat={sat} unsat={unsat} timeout={timeout} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
