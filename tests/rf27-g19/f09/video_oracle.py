#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x271909); h=hashlib.sha256(); accepted=denied=0
for _ in range(5000):
    cap=r.randint(1,16); queue=[]; last=-1
    for _ in range(r.randint(1,48)):
        op=r.randrange(4)
        if op<2:
            ts=r.randint(0,500)
            if len(queue)>=cap or ts<last:
                denied+=1; result="deny"
            else:
                queue.append(ts); last=ts; accepted+=1; result="push"
        elif op==2:
            result=f"pop:{queue.pop(0)}" if queue else "empty"
        else:
            queue.clear(); result="cancel"
        h.update(f"{cap}:{result}:{len(queue)}\n".encode())
print(f"RF27_G19_F09_ORACLE=PASS seed=0x271909 cases=5000 accepted={accepted} denied={denied} digest={h.hexdigest()}")
