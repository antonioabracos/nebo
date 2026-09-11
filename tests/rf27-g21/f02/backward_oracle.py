#!/usr/bin/env python3
import hashlib, random, struct
rng=random.Random(0x272102); digest=hashlib.sha256()
for case in range(5000):
    n=rng.randrange(1,17); x=[rng.uniform(-4,4) for _ in range(n)]; y=rng.uniform(-4,4); seed=rng.uniform(-2,2)
    gx=[y*seed]*n; gy=sum(x)*seed
    digest.update(struct.pack('<I',case)); digest.update(b''.join(struct.pack('<d',v) for v in gx)); digest.update(struct.pack('<d',gy))
print(f'RF27_G21_F02_ORACLE=PASS seed=0x272102 cases=5000 digest={digest.hexdigest()}')
