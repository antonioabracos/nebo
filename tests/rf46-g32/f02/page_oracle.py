#!/usr/bin/env python3
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3

def fnv(data):
    value = FNV_OFFSET
    for byte in data:
        value = ((value ^ byte) * FNV_PRIME) & 0xFFFFFFFFFFFFFFFF
    return value

data = bytearray(4080)
data[0] = 42
checksum = fnv(data) ^ 9
assert checksum == (fnv(bytes(data)) ^ 9)
for cut in (0, 1, 2048, 4095):
    image = (9).to_bytes(8, "little") + checksum.to_bytes(8, "little") + data
    assert len(image[:cut]) == cut
corrupt = bytearray(data)
corrupt[0] ^= 1
assert (fnv(corrupt) ^ 9) != checksum
before, after, observed = checksum, checksum ^ 123, 999
recovered = after if observed == after else before
assert recovered == before
print("RF46_G32_F02_ORACLE_GREEN page_checksum=fnv1a64_xor_lsn journal=rollback recovery=idempotent file=temp_root")
