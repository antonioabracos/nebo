# G03-PF002 fixtures

Files 001–006 are parser/API goldens for the five names frozen by G03-PF001.
They prove receiver-first, zero-argument call syntax and the explicit/implicit
`Int.toFloat()` pair. The negative-zero parser golden uses
`(-0.0).isNegativeZero()` because suffix calls bind more tightly than unary
minus; the unparenthesized form has a different AST. Files 007–017 freeze provisional negative diagnostics for
wrong arity, forbidden aliases, receiver mismatch, deferred APIs, implicit
coercion, cast syntax, cross-type constructors and unknown numeric APIs.

G03-PF002 does not link the isolated contract into `neboc`. Consequently every
new source remains rejected by the public CLI until later explicitly authorized
semantic, native and vertical fronts. A parser/API golden is not an executable
language feature.
