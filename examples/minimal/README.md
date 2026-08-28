# Minimal Nebo examples

`start-empty.no` is the first complete Nebo program compiled and executed by the native Assembly compiler. It has no output and must terminate with exit code `0`.

`int-bool-arithmetic.no` is the first checked arithmetic example; its result is intentionally discarded because `.return` is reserved for MF038.

The repository-level `examples/soma.no` demonstrates the MF038 receiver-first call `2.soma(3)`.


`control-text.no` demonstrates the MF039 declaration equivalence, Text equality
and deterministic `if/else` result.
