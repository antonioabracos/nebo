# MF018 statements and control

```txt
Statement grammar:
if-statement | while-statement | loop-statement | range-for-statement | break | continue |
expression semicolon

Expression statement classification:
BindingTerminal -> BindingStmt
ReturnTerminal -> ReturnStmt
otherwise -> ExpressionStmt

if:
if (expression) block [else block | else if]

range-for:
for (identifier in identifier) block

Deferred control:
when switch -> NEBO_PARSE_UNSUPPORTED_CONTROL

RF27-G02-F06 activates canonical pre-test `while (condition) { ... }` plus the
bounded cleanup-control forms `loop { ... }`, `break;`, and `continue;` as
structural AST, semantic CFG and deterministic native labels. General iterator
RF27-G02-F07 adds the structural `RangeForStmt` shape and the bounded G06
iterator vertical supplies type, cardinality and native sequential execution.
General iterator protocols and panic unwinding remain outside this profile.

Canonical Nebo 1.0 control headers are the sole public grammar. The bounded
offline migration tool is `tools/nebo-control-header-migrate.py`; it defaults
to check-only and requires literal `--apply` to write. `loop { ... }` never
takes a condition or parentheses. `do-while` remains post-1.0.

Invalid fluent control:
condicao.if -> NEBO_PARSE_INVALID_CONTROL_CHAIN
```

Each block remains a structural scope node. The parser does not infer types;
the RF27 bindings vertical owns Bool conditions, lexical targets and CFG flow.
