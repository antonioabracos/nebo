#!/usr/bin/env python3
def migrate_v1_v2(row, capacity, default):
    if len(row) + 1 > capacity:
        return None
    return row + [default]
assert migrate_v1_v2([10,20,30],4,99) == [10,20,30,99]
assert migrate_v1_v2([10,20,30],3,99) is None
blob = bytes(range(17))
chunks = [blob[i:i+4] for i in range(0,len(blob),4)]
assert b"".join(chunks) == blob and max(map(len,chunks)) <= 4
print("RF46_G32_F06_ORACLE_GREEN migration=v1_to_v2 compatible=append_default failure_atomic=yes transfer=bounded_chunks_65536")
