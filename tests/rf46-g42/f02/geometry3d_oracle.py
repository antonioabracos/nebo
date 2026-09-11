#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002a00000002
VALUES=[19, 38, 57, 76]
MAX_RECORDS=26
ITEM_MAX=1073728
ORDERED=False

def evaluate(values):
    assert 0 < len(values) <= MAX_RECORDS
    assert all(0 <= value <= ITEM_MAX for value in values)
    if ORDERED:
        assert all(left <= right for left,right in zip(values,values[1:]))
    total=sum(values)
    assert total <= MASK
    digest=0xCBF29CE484222325 ^ PROFILE
    for value in values:
        digest=((digest ^ value)*0x100000001B3)&MASK
    return total,digest,min(values),max(values)

result=evaluate(VALUES)
assert result==(190,0x489f5a873e9acd9b,19,76)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G42_F02_ORACLE_PASS schema=geometry3d count=4 sum=%d hash=%016x" % result[:2])
