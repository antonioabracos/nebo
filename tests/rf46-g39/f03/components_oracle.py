#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002700000003
VALUES=[11, 22, 33, 44]
MAX_RECORDS=18
ITEM_MAX=1040960
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
assert result==(110,0x71e63410e3e5682e,11,44)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G39_F03_ORACLE_PASS schema=components count=4 sum=%d hash=%016x" % result[:2])
