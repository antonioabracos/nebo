# MF016 provisional AST base

`AstNode` is a compact 80-byte record with 1-based `NodeId` values. `0` is
invalid. The builder is caller-backed and mutable only during parsing.

MF016 node kinds are limited to:

```txt
Program
StartDecl
FunctionDecl
Receiver
Parameter
Block
```

Block bodies retain a token interval (`payload0 = first token index`,
`payload1 = token count`) and are intentionally opaque. Expressions,
statements, semantic types and immutable final storage remain MF017–MF020.
