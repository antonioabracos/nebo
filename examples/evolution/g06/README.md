# G06/RF27 bounded Result example

`../g06-option-result.no` is the stable executable candidate example for the
current bounded tagged-value surface. It constructs `Result<Int,Bool>`, reads
the active `Ok` payload with `get`, and returns the value natively.

The example is validated through `neboc check`, deterministic `emit-asm`,
`build`, static ELF inspection and native execution. The broader Option,
Result, propagation and match matrices live under `tests/rf27-g05/`.
