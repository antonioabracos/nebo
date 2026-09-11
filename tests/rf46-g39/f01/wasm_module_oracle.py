#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002700000001
VALUES=[9, 18, 27, 36]
MAX_RECORDS=16
ITEM_MAX=1032768
ORDERED=True
MAX_BYTES=1<<20
MAX_SECTIONS=64

def decode_u32(data, offset):
    value=0
    for count in range(1,5):
        assert offset < len(data), "truncated LEB128"
        byte=data[offset]; offset+=1
        payload=byte & 0x7f
        value |= payload << (7*(count-1))
        if not byte & 0x80:
            assert count == 1 or payload != 0, "non-canonical LEB128"
            return value,offset
    raise AssertionError("oversized LEB128")

def validate_module(data):
    assert 8 <= len(data) <= MAX_BYTES
    assert data[:4] == b"\x00asm"
    assert data[4:8] == b"\x01\x00\x00\x00"
    offset=8; count=0; last=0; payload_bytes=0
    while offset < len(data):
        section=data[offset]; offset+=1
        assert section <= 11
        if section:
            assert section > last
            last=section
        count+=1
        assert count <= MAX_SECTIONS
        size,offset=decode_u32(data,offset)
        payload_bytes+=size
        assert payload_bytes <= MAX_BYTES
        offset+=size
        assert offset <= len(data)
    digest=0xCBF29CE484222325 ^ PROFILE
    for byte in data:
        digest=((digest ^ byte)*0x100000001B3)&MASK
    return count,len(data),digest,last,payload_bytes

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
assert result==(90,0x93c73c10f6de4ab8,9,36)
module=bytes([0,0x61,0x73,0x6d,1,0,0,0,1,1,0,5,4,1,1,1,16,10,1,0])
module_result=validate_module(module)
assert module_result[0:2] == (3,20)
assert module_result[3:] == (10,6)
for malformed in (
    bytes([1,0x61,0x73,0x6d,1,0,0,0]),
    bytes([0,0x61,0x73,0x6d,1,0,0,0,5,1,0,1,1,0]),
    bytes([0,0x61,0x73,0x6d,1,0,0,0,1,2,0]),
    bytes([0,0x61,0x73,0x6d,1,0,0,0,1,0x80,0]),
):
    try:
        validate_module(malformed)
        raise RuntimeError("malformed module accepted")
    except AssertionError:
        pass
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G39_F01_ORACLE_PASS schema=wasm_module sections=%d bytes=%d hash=%016x last=%d payload=%d" % module_result)
