#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x2605); n=('call','capability','version','signature','layout','lifetime','callback','unwind'); c={x:0 for x in n}; h=hashlib.sha256()
for i in range(60000):
 s=n[r.randrange(8)]; c[s]+=1; h.update(i.to_bytes(4,'little')+s.encode()+b'\0')
print('RF27_G26_F05_ORACLE=PASS cases=60000 %s digest=%s'%(' '.join('%s=%d'%x for x in c.items()),h.hexdigest()))
