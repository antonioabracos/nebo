#!/usr/bin/env python3
edges=[(1,2),(2,3),(1,4)]
def path(start,target,depth):
    frontier={start}
    for _ in range(depth+1):
        if target in frontier:return True
        frontier |= {b for a,b in edges if a in frontier}
    return False
assert path(1,3,2) and not path(4,3,2)
types={1:set(),2:{1},3:{2}}
assert all(t not in parents for t,parents in types.items())
print("RF46_G34_F02_ORACLE_GREEN ontology=nominal path=bfs_bitset depth=16 validation=no_repair constraints=explicit")
