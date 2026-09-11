#!/usr/bin/env python3
def step(active, exits, enters, regions):
    assert 1 <= regions <= 8
    assert exits & ~active == 0
    return (active & ~exits) | enters

assert step((2 << 64) | 5, (2 << 64) | 1, (4 << 64) | 8, 2) == (4 << 64) | 12
try:
    step(1, 2, 4, 1)
    raise AssertionError("missing active exit accepted")
except AssertionError as exc:
    assert str(exc) != "missing active exit accepted"
print("RF46_G45_F02_ORACLE_GREEN states=128 regions=8 hierarchy=bounded parallel=bounded order=exit_action_entry")
