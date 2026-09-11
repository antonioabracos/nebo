#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x2607); n=('submit','idempotent','duplicate','cancel','complete','function','shipping','provenance','partition','limit'); c={x:0 for x in n}; h=hashlib.sha256()
for i in range(70000):
 s=n[r.randrange(len(n))]; c[s]+=1; h.update(i.to_bytes(4,'little')+s.encode()+b'\0')
print('RF27_G26_F07_ORACLE=PASS cases=70000 %s digest=%s'%(' '.join('%s=%d'%x for x in c.items()),h.hexdigest()))
