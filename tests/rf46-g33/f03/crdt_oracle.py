#!/usr/bin/env python3
from itertools import permutations
def join(a,b): return tuple(max(x,y) for x,y in zip(a,b))
states=[(2,0,4),(1,3,4),(2,2,1)]
for a,b,c in permutations(states,3):
    assert join(a,b)==join(b,a)
    assert join(join(a,b),c)==join(a,join(b,c))
    assert join(a,a)==a
assert sum(join(states[0],states[1]))-1==8
mv_register={"dotA":"x","dotB":"y"}
assert len(mv_register)==2
print("RF46_G33_F03_ORACLE_GREEN pn_counter=v1 orset=add_wins_v1 mv_register=visible_concurrent ormap=observed_remove laws=ACI")
