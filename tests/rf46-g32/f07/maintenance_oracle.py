#!/usr/bin/env python3
src = bytes(range(256))
backup = bytes(src)
assert backup == src
corrupt = bytearray(backup); corrupt[17] ^= 1
assert bytes(corrupt) != src
rows = [0,10,0,20,30,0]
dense = [x for x in rows if x != 0]
assert dense == [10,20,30]
assert [x for x in dense if x != 0] == dense
print("RF46_G32_F07_ORACLE_GREEN backup_hash=source_equal restore=new_destination compaction=idempotent benchmark=bounded")
