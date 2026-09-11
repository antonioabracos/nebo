#!/usr/bin/env python3
rows = [(0, 9, 100), (10, 19, 200), (20, 29, 300)]
generated = [(lo, rows[i][2]) for i, (lo, hi, _) in enumerate(rows)] + [(hi, rows[i][2]) for i, (lo, hi, _) in enumerate(rows)]
for value, expected in generated:
    hits = [(i, result) for i, (lo, hi, result) in enumerate(rows) if lo <= value <= hi]
    assert len(hits) == 1 and hits[0][1] == expected
assert all(any(lo <= value <= hi for lo, hi, _ in rows) for value in range(30))
print(f"RF46_G45_F06_ORACLE_GREEN rows=3 generated_tests={len(generated)} coverage=complete conflicts=typed hit_policy=unique")
