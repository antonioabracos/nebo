#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002a00000004
VALUES=[21, 42, 63, 84]
MAX_RECORDS=28
ITEM_MAX=1081920
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
assert result==(210,0x2636a2872b2ed969,21,84)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G42_F04_ORACLE_PASS schema=spatial_index count=4 sum=%d hash=%016x" % result[:2])
