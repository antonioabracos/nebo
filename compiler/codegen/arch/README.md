# Architecture backends

Only `x86_64-systemv-elf-linux` exists. Backend selection is driven exclusively
by the frozen `TargetContext`; there is no host autodetection or fallback.
