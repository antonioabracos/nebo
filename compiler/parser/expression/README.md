# MF017 Pratt expressions

```txt
Primary:
identifier, Int, Text, true, false, grouping

Unary:
- !

Binary precedence, low to high:
||
&&
== !=
< <= > >=
+ -
* / %

Suffix:
.receiver(arguments)
.binding
.return
```

Calls are receiver-first. A bare `.identifier` is represented as a terminal
binding node rather than field access. `.return` is represented as a terminal
node but statement/control semantics remain deferred to MF018.

No behavior classification, overload resolution, name resolution, type checking
or field access is performed in this front.
