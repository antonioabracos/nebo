# Runtime traps v0

MF037 freezes deterministic checked-Int trap reasons. `nebo_runtime_trap_overflow` exits with status `172` (`128 + 44`); `nebo_runtime_trap_division_by_zero` exits with status `173` (`128 + 45`). Traps write no stdout/stderr and do not unwind.
