# MF031 target tests

The native test covers the first frozen target tuple, exact `DataLayout`, feature
validation, deterministic hashes and explicit rejection of incomplete or unsupported
combinations. Scenario 4 implements `NEBO-ABI-NEG-007`.

MF031-R1 adds infrastructure scenarios `A`, `B` and `C` for direct `DataLayout`
hash corruption, target tuple hash corruption and mirrored layout-hash corruption.
The complete native matrix is `1..9 A B C`.
