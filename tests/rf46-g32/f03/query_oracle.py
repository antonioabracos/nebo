#!/usr/bin/env python3
rows = [3, 10, 7, 12, 2]
def execute(values, threshold, limit):
    assert 0 < limit <= 4096
    selected = [v for v in values if v >= threshold][:limit]
    return len(selected), sum(selected)
assert execute(rows, 7, 2) == (2, 17)
assert execute(rows, 0, 5) == (5, 34)
assert execute(list(reversed(rows)), 7, 2) == (2, 19)
print("RF46_G32_F03_ORACLE_GREEN typed_plan=yes scan_filter_project=yes collect_limit=4096 stream_buffer=64")
