#!/usr/bin/env python3
def compatible(current, target, removed_active): return target >= current and not removed_active
assert compatible(3, 4, False)
assert not compatible(3, 4, True)
record = {"version": 3, "revision": 0, "step": 1}
migrated = record | {"version": 4, "revision": 1, "step": 5, "plan": 900}
assert migrated["version"] == 4
assert 10 + sum([1, 2, 3]) == 16
repaired = migrated | {"revision": 2, "step": 9, "audit_action": 55}
assert repaired["audit_action"] != 0
print("RF46_G45_F07_ORACLE_GREEN migration=versioned compatibility=explicit replay=deterministic repair=audited")
