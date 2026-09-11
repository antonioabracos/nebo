#!/usr/bin/env python3
import struct

MAGIC = b"NEBODB01"
VERSION = 1
PAGE_SIZE = 4096
MAX_PAGES = 16384

def fnv1a64(data):
    value = 0xCBF29CE484222325
    for byte in data:
        value ^= byte
        value = (value * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return value

def header(pages, schema_version, schema_hash):
    assert 0 < pages <= MAX_PAGES
    prefix = struct.pack("<8sIIQQQQ", MAGIC, VERSION, 0, PAGE_SIZE, pages,
                         schema_version, schema_hash)
    return prefix + struct.pack("<Q", fnv1a64(prefix))

blob = header(16, 7, 0x12345678)
assert len(blob) == 56
assert fnv1a64(blob[:48]) == struct.unpack_from("<Q", blob, 48)[0]
corrupt = bytearray(blob)
corrupt[40] ^= 1
assert fnv1a64(corrupt[:48]) != struct.unpack_from("<Q", corrupt, 48)[0]
print("RF46_G32_F01_ORACLE_GREEN format=NEBODB01 version=1 page=4096 checksum=fnv1a64 bounds=checked")
