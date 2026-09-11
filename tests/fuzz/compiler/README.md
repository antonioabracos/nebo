# Compiler fuzz corpus policy — MF056

The executable corpus is generated deterministically by `scripts/mf056/compiler_fuzz.py` from a fixed seed. Inputs are bounded by CPU, address-space, file-size, descriptor and wall-clock limits. No failing case is retried or silently ignored.
