# x86-64 Core value codegen

`value_codegen.asm` walks the real 1-based AST produced by the parser. Integer arithmetic uses `jo` checked edges, signed division rejects zero and `INT64_MIN / -1`, comparisons use `setcc` followed by zero extension, and Boolean operators canonicalize every result to `0` or `1`.
