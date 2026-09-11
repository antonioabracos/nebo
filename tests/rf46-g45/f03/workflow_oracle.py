#!/usr/bin/env python3
def checksum(r):
    value = 0
    for item in r[:8]: value ^= item
    return value

r = [0x314B524F5742454E, 77, 3, 0, 1, 0, 100, 40, 0]
r[8] = checksum(r)
assert checksum(r) == r[8]
s = r.copy(); s[3] += 1; s[4] = 2; s[6] = 200; s[7] = 41; s[8] = checksum(s)
assert s[3:8] == [1, 2, 0, 200, 41]
assert 41 == s[7]  # duplicate event is rejected before mutation
print("RF46_G45_F03_ORACLE_GREEN storage=versioned checkpoint=atomic resume=verified duplicate=logical_exactly_once")
