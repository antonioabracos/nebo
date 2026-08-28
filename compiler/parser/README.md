# Nebo parser

The parser is deterministic recursive descent over the complete token stream.
The Nebo 1.0 structural grammar includes:

```txt
Program       := (StartDecl | FunctionDecl)* EOF
StartDecl     := start ( ) Block
FunctionDecl  := ( Type . receiver ) name ( Parameters? ) Block
Parameter     := Type . name
Block         := { Statement* }
IfStmt        := if ( Expression ) Block (else (Block | IfStmt))?
WhileStmt     := while ( Expression ) Block
LoopStmt      := loop Block
RangeForStmt  := for ( Identifier in Identifier ) Block
```

Blocks are balanced and nesting-limited. `if`, `while`, and `for` headers are
parenthesized; `loop` is deliberately conditionless. Legacy unparenthesized
`while`/`for` headers produce stable diagnostics 158/159 with bounded insertion
fix-its. `when`, `switch`, and `do-while` are not Nebo 1.0 productions.
