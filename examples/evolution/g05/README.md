# G05 immutable bindings and definite assignment

`../g05-bindings-definite-assignment.no` is the stable executable candidate
example for the bounded G05 surface. It demonstrates typed declaration without
an initial value, exactly one initialization, explicit and implicit initializer
equivalence, one-level `if/else` definite assignment and reads after the
compiler has proved initialization.

The example is validated by `neboc check`, `emit-asm`, `build`, static ELF
inspection and native execution. Assignment syntax, mutable bindings,
`const`, shadowing and named arguments remain unavailable.
