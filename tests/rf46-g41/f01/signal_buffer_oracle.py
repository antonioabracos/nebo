#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002900000001
VALUES=[15, 30, 45, 60]
MAX_RECORDS=22
ITEM_MAX=1057344
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
assert result==(150,0x3c4585aa98be56a4,15,60)
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G41_F01_ORACLE_PASS schema=signal_buffer count=4 sum=%d hash=%016x" % result[:2])
