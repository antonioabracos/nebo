#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002a00000003
VALUES=[20, 40, 60, 80]
MAX_RECORDS=27
ITEM_MAX=1077824
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
assert result==(200,0x33adee758832f486,20,80)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G42_F03_ORACLE_PASS schema=mesh count=4 sum=%d hash=%016x" % result[:2])
