# Nebo structural AST

`AstNode` is a compact 80-byte record with 1-based `NodeId` values. `0` is
invalid. The builder is caller-backed and mutable only during parsing.

The stable structural set includes the declaration base plus expression and
statement nodes. Control nodes relevant to Nebo 1.0 are:

```txt
IfStmt(condition, thenBlock, optionalElse)
WhileStmt(condition, body)
LoopStmt(body)
RangeForStmt(binding, iterable, body)
```

Parentheses are parser delimiters and do not add AST nodes. Consequently the
C02 canonical control-header migration preserves node kinds, child order,
source ownership, CFG inputs, runtime behavior, and the public ABI.
