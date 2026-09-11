# MF050 headless concurrency composites

`mf050_enter_pressure_test.asm` adds the two cross-layer boundaries not covered by a single earlier front:

1. ENTER resolves exactly once while the Console command queue is full, without consuming or reordering queued commands.
2. Close under a full queue fails atomically, then succeeds after owner progress and reaches `CLOSED_WAITING_RECLAIM` without use-after-free.
