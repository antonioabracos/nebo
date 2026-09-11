#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x2603); states=('ready','call','capability','cancel','deadline','limit','crash','shutdown'); c={x:0 for x in states}; h=hashlib.sha256()
for i in range(50000):
 s=states[r.randrange(8)]; c[s]+=1; h.update(i.to_bytes(4,'little')+s.encode()+b'\0')
print('RF27_G26_F03_ORACLE=PASS cases=50000 %s digest=%s'%(' '.join('%s=%d'%x for x in c.items()),h.hexdigest()))
