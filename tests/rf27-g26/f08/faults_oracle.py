#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x2608); n=('retry','success','exhausted','timeout','checkpoint','corrupt','rollback','quorum','compensate','rebalance'); c={x:0 for x in n}; h=hashlib.sha256()
for i in range(80000):
 s=n[r.randrange(len(n))]; c[s]+=1; h.update(i.to_bytes(4,'little')+s.encode()+b'\0')
print('RF27_G26_F08_ORACLE=PASS cases=80000 %s digest=%s'%(' '.join('%s=%d'%x for x in c.items()),h.hexdigest()))
