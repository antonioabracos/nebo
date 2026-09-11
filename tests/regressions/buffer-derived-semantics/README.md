# Buffer-derived semantics regression

This regression closes the automatic-oracle gap exposed by the historical
Nebo 1.0 practical inventory. It covers canonical `Buffer.view`/`Slice.sum`,
exact `Buffer.get` Option identity, `Buffer.freeze`/Bytes reconstruction,
explicit Console newline bytes, and fail-closed transcript validation.

The historical inventory is immutable. Its `stockList.stockView(...)` spelling
is classified as a fixture-contract mismatch: public RF27 authority requires
`stockList.view(...)`. The machine and readable fixtures use the public form.

Run `bash tests/regressions/buffer-derived-semantics/validate.sh`. The validator
is headless, offline, deterministic, builds real static product ELFs, executes
the generated programs through a syscall-only capture shim, and rejects the
first semantic mismatch.
