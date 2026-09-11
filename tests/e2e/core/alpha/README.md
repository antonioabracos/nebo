# Core Native Alpha E2E

`invalid-source.no` is intentionally invalid: an explicit `Bool` assertion
wraps an `Int`. MF040 proves deterministic rejection by all public compilation
modes and proves that no output or temporary artifact is created or replaced.
