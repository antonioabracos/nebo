# x86-64 Receiver-First Functions

`function_codegen.asm` consumes the materialized AST, frozen target context, Function Lowering Plan records and the System V AMD64 ABI Adapter.

MF038 supports:

- receiver in `RDI`;
- positional parameters in `RSI`, `RDX`, `RCX`, `R8`, `R9`;
- deterministic local frame slots;
- checked `Int`/canonical `Bool` expressions;
- receiver-first direct calls;
- terminal `.return` with the scalar result in `RAX`;
- source-order name mangling `nebo_fn_<id>`.

Recursion, forward calls between receiver-first functions, stack-passed parameters and control-flow statements are outside MF038.
