#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x271908); h=hashlib.sha256()
def sat(v): return max(-32768,min(32767,v))
for _ in range(5000):
    a=r.randint(-32768,32767); b=r.randint(-32768,32767); g=r.randint(0,32768)
    p=b*g
    scaled=(p+16384)//32768 if p>=0 else (p+16383)//32768
    mixed=sat(a+scaled)
    frac=r.randrange(65536); c=r.randint(-32768,32767); d=r.randint(-32768,32767)
    q=c*(65536-frac)+d*frac
    interp=(q+32768)//65536 if q>=0 else (q+32767)//65536
    h.update(f"{a},{b},{g},{mixed},{c},{d},{frac},{interp}\n".encode())
print(f"RF27_G19_F08_ORACLE=PASS seed=0x271908 cases=5000 digest={h.hexdigest()}")
