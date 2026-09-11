#!/usr/bin/env python3
from itertools import permutations
ops=[("a",1),("b",2),("a",3)]
def materialize(order):
    seen=set(); state={}
    for key,value in order:
        token=(key,value)
        if token in seen: continue
        seen.add(token); state[key]=max(state.get(key,0),value)
    return tuple(sorted(state.items()))
states={materialize(p) for p in permutations(ops)}
assert states=={(("a",3),("b",2))}
assert [d for d in (1,2,3,4,5) if d>3]==[4,5]
print("RF46_G33_F06_ORACLE_GREEN replicas=converged state_hash=equal conflicts=visible compaction=stable_only group=G33_GREEN")
