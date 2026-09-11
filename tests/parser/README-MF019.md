# MF019 negative parser fixtures

```txt
NEBO-PARSE-NEG-009:
missing semicolon -> diagnostic + recovered ErrorNode

NEBO-PARSE-NEG-014:
nesting above configured limit -> LIMIT_EXCEEDED + ErrorNode

Internal coverage:
unexpected token; diagnostic cap; token cap; AST-node cap
```
