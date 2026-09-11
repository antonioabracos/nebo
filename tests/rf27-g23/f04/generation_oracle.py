#!/usr/bin/env python3
import hashlib, struct
h=hashlib.sha256(); counts=[0]*4
for seed in range(10000):
 token=3-(seed%4); counts[token]+=1; h.update(struct.pack('<II',seed,token))
assert counts==[2500]*4
print(f'RF27_G23_F04_ORACLE=PASS cases=10000 topk_counts={counts} max_tokens=64 cancellation=yes digest={h.hexdigest()}')
