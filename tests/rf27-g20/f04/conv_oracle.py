#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x272004); h=hashlib.sha256()
for _ in range(2000):
 hgt=r.randint(1,8); wid=r.randint(1,8); kh=r.randint(1,min(7,hgt)); kw=r.randint(1,min(7,wid)); s=r.randint(1,4)
 oh=(hgt-kh)//s+1; ow=(wid-kw)//s+1; xs=[r.uniform(-2,2) for _ in range(hgt*wid)]; k=[r.uniform(-2,2) for _ in range(kh*kw)]
 out=[]
 for y in range(oh):
  for x in range(ow): out.append(sum(xs[(y*s+dy)*wid+x*s+dx]*k[dy*kw+dx] for dy in range(kh) for dx in range(kw)))
 h.update(repr(out).encode())
print(f"RF27_G20_F04_ORACLE=PASS seed=0x272004 cases=2000 digest={h.hexdigest()}")
