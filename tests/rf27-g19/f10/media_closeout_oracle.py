#!/usr/bin/env python3
import hashlib,random,struct
r=random.Random(0x271910); h=hashlib.sha256(); denied=0
for i in range(10000):
    width=r.randint(1,64); height=r.randint(1,64); bpp=r.choice((24,32))
    row=(width*(bpp//8)+3)&~3; size=54+row*height
    capacity=r.randint(0,16); pushes=r.randint(0,32)
    q=[]; last=-1
    for _ in range(pushes):
        ts=r.randint(0,4096)
        if len(q)>=capacity or ts<last:
            denied+=1
        else:
            q.append(ts); last=ts
    gain=r.randint(0,32768); a=r.randint(-32768,32767); b=r.randint(-32768,32767)
    p=b*gain; scaled=(p+16384)//32768 if p>=0 else (p+16383)//32768
    mixed=max(-32768,min(32767,a+scaled))
    h.update(struct.pack("<IIIIii",width,height,bpp,size,mixed,len(q)))
print(f"RF27_G19_F10_ORACLE=PASS seed=0x271910 cases=10000 denied={denied} digest={h.hexdigest()}")
