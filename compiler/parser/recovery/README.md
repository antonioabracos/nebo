# MF019 parser recovery

```txt
Synchronization tokens:
semicolon; right brace; EOF

Progress rule:
a recovery call never moves the token cursor backwards and consumes a boundary
when it starts directly on that boundary.

Error representation:
ErrorNode only; partial AST nodes from the failed statement are rolled back.

Default maximum diagnostics:
8

Limits:
tokens; AST nodes; nesting; diagnostics

Semantic validation of ErrorNode:
NOT_IMPLEMENTED
```
