#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002900000002
VALUES=[16, 32, 48, 64]
MAX_RECORDS=23
ITEM_MAX=1061440
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
assert result==(160,0xb88b9e0e1066e177,16,64)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G41_F02_ORACLE_PASS schema=filter_estimator count=4 sum=%d hash=%016x" % result[:2])
