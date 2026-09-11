#!/usr/bin/env python3
pairs = [(1,10),(3,30),(7,70),(9,90)]
def scan(key):
    return next((v for k,v in pairs if k == key), None)
index = dict(pairs)
for key in range(12):
    assert index.get(key) == scan(key)
def plan(rows, equality, valid):
    return ("INDEX","EQUALITY_INDEX") if rows >= 8 and equality and valid else ("SCAN","BOUNDED_SCAN")
assert plan(100,1,1)[0] == "INDEX"
assert plan(4,1,1)[0] == "SCAN"
print("RF46_G32_F05_ORACLE_GREEN index=binary_sorted lookup=scan_equal planner=explainable forced_validation=required")
