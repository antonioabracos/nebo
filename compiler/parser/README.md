# MF016 parser skeleton

The parser is deterministic recursive descent over the complete MF015 token
stream. It recognizes only the top-level structural grammar:

```txt
Program       := (StartDecl | FunctionDecl)* EOF
StartDecl     := start ( ) Block
FunctionDecl  := ( Type . receiver ) name ( Parameters? ) Block
Parameter     := Type . name
Block         := { opaque-token-interval }
```

Blocks are balanced and nesting-limited, but their statements and expressions
remain opaque until MF017–MF019. Top-level statements and duplicate `start()`
produce stable parser diagnostics.
