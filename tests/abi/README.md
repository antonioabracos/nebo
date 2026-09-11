# MF033 ABI tests

`mf033_abi_test` accepts a zero-argument no-C smoke invocation and scenarios
`1..9`:

1. internal ABI version and masks;
2. register/stack parameter layout and 16-byte frame alignment;
3. preserved-register function form;
4. six register arguments plus stack arguments;
5. scalar and Status returns;
6. runtime thunk with ABI version guard;
7. runtime version mismatch;
8. canonical function-call golden;
9. signature-hash tamper rejection.

The goldens are NASM Intel sources. Runtime thunk externals remain unresolved by
design until the runtime/format fronts.
