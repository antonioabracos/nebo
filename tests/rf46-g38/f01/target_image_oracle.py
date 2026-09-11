#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002600000001
VALUES=[2, 4, 6, 8]
MAX_RECORDS=9
ITEM_MAX=1004096
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
assert result==(20,0x9ca9c74607a983ec,2,8)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G38_F01_ORACLE_PASS schema=target_image count=4 sum=%d hash=%016x" % result[:2])
