#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002900000003
VALUES=[17, 34, 51, 68]
MAX_RECORDS=24
ITEM_MAX=1065536
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
assert result==(170,0xca4ebe0e1a962de2,17,68)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G41_F03_ORACLE_PASS schema=control_core count=4 sum=%d hash=%016x" % result[:2])
