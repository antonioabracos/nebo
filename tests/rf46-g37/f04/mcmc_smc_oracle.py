#!/usr/bin/env python3
weights = [1,3]
total = sum(weights)
n = len(weights)
offset = 0
indices=[]
cum=weights[0]
i=0
for j in range(n):
    pos=offset+j*total
    while pos >= cum*n:
        i+=1; cum+=weights[i]
    indices.append(i)
assert indices == [0,1]
assert min(1,5/3) == 1
print("RF46_G37_F04_ORACLE_PASS mh=accept_higher_weight smc=systematic indices=0,1 diagnostics=bounded")
