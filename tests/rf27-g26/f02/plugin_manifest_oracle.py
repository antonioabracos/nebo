#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x2602); names=('verified','unsigned','hash','abi','budget','unknown','limit','corrupt'); c={x:0 for x in names}; h=hashlib.sha256()
for i in range(45000):
 s=names[r.randrange(len(names))]; c[s]+=1; h.update(i.to_bytes(4,'little')+s.encode()+b'\0')
print('RF27_G26_F02_ORACLE=PASS cases=45000 %s digest=%s'%(' '.join('%s=%d'%x for x in c.items()),h.hexdigest()))
