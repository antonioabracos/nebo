# MF023 call and signature tests

`mf023_call_test.asm` is a parameterized ELF64 Assembly test for the nine
primary MF023 contracts. It covers deterministic FunctionIds, inferred return
signatures, receiver-first overload selection, positional arity/type checks,
Void binding rejection, and stable acyclic call-graph ordering.

Run scenarios `1` through `9`; execution without a scenario returns `64`.
