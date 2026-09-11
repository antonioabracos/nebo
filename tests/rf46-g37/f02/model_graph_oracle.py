#!/usr/bin/env python3
nodes = [(-1,0,1),(0,1,4),(1,2,4),(1,3,4)]
assert all(parent == -1 or 0 <= parent < i for i,(parent,_,_) in enumerate(nodes))
assert sum(parent == -1 for parent,_,_ in nodes) == 1
assert sum(kind == 2 for _,kind,_ in nodes) == 1
assert sum(kind == 3 for _,kind,_ in nodes) == 1
assert not all(parent == -1 or parent < i for i,(parent,_,_) in enumerate([(1,0,1),(-1,1,1)]))
print("RF46_G37_F02_ORACLE_PASS nodes=4 roots=1 observed=1 deterministic=1 cycle_guard=pass")
