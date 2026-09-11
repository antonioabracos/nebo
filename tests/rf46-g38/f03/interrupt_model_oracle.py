#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002600000003
VALUES=[4, 8, 12, 16]
MAX_RECORDS=11
ITEM_MAX=1012288
ORDERED=True

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
assert result==(40,0x3f509724c2612bc6,4,16)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G38_F03_ORACLE_PASS schema=interrupt_model count=4 sum=%d hash=%016x" % result[:2])
