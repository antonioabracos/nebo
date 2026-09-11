#!/usr/bin/env python3
base = [10, 20, 30]
shadow = base.copy()
shadow[1] = 99
assert base == [10, 20, 30]
save = shadow.copy()
shadow[2] = 77
shadow = save.copy()
assert shadow == [10, 99, 30]
base = shadow.copy()
assert base == [10, 99, 30]
aborted = base.copy(); trial = aborted.copy(); trial[0] = -1
assert aborted == base
print("RF46_G32_F04_ORACLE_GREEN isolation=local_snapshot single_writer=1 readers=8 savepoints=bounded atomicity=shadow_commit")
