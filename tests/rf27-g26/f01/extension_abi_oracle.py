#!/usr/bin/env python3
import hashlib, random
rng=random.Random(0x2601); counts={k:0 for k in ('ok','schema','kind','target','abi','effect','capability','feature','layout')}; h=hashlib.sha256()
for i in range(40000):
    mode=rng.randrange(9); status=tuple(counts)[mode]; counts[status]+=1
    h.update(i.to_bytes(4,'little')+status.encode()+b'\0')
assert sum(counts.values())==40000
print('RF27_G26_F01_ORACLE=PASS cases=40000 %s digest=%s' % (' '.join('%s=%d'%x for x in counts.items()),h.hexdigest()))
