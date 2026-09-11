#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002600000004
VALUES=[5, 10, 15, 20]
MAX_RECORDS=12
ITEM_MAX=1016384
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
assert result==(50,0x06344b352a483689,5,20)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G38_F04_ORACLE_PASS schema=peripherals count=4 sum=%d hash=%016x" % result[:2])
