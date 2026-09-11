#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002b00000001
VALUES=[29, 58, 87, 116]
MAX_RECORDS=36
ITEM_MAX=1114688
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
assert result==(290,0xed3ec341768c8ba8,29,116)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G43_F01_ORACLE_PASS schema=ecs_storage count=4 sum=%d hash=%016x" % result[:2])
