# Immutable AstStore — MF020

`AstStore` is a caller-backed immutable copy of the provisional parser nodes.

```txt
NodeId:
1-based array index

Invalid NodeId:
0

Pointer-derived IDs:
FORBIDDEN

AstNode physical size:
80 bytes

Parent links:
separate structural side table

Freeze:
finalizes AstBuilder, copies nodes, validates invariants, records hash

Mutation API after freeze:
ABSENT

Raw-memory mutation detection:
hash verification

ErrorNode:
structurally valid, but blocks require_clean
```

The store contains syntax only. Type, symbol, effect, call, route and control
metadata belong to future semantic side tables and are not duplicated in an
`AstNode`.

No HIR, MIR or LIR is created or required by this store.
