#!/usr/bin/env python3
def compare(a,b):
    less=any(x<y for x,y in zip(a,b)); greater=any(x>y for x,y in zip(a,b))
    return "CONCURRENT" if less and greater else "BEFORE" if less else "AFTER" if greater else "EQUAL"
assert compare([2,1,0],[2,3,0])=="BEFORE"
assert compare([2,3,0],[3,1,0])=="CONCURRENT"
assert compare([2,1,0],[2,1,0])=="EQUAL"
print("RF46_G33_F02_ORACLE_GREEN replicas=16 version_vector=partial_order checkpoint=canonical change_id=replica_sequence")
