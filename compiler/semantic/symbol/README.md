# SymbolTable and name resolution — MF021

MF021 collects top-level functions before resolving lexical values, so a call
may reference a function declared later in the source. Functions use a separate
namespace from receiver, parameter and binding values.

Bindings become visible only after their initializer has been visited.
Duplicates in one scope, shadowing of an outer value and reserved declaration
names produce deterministic NAME diagnostics. `SymbolId` values are stable
1-based source-order indices and node associations live in side tables.

Type checking, overload selection, modules and code generation are deferred.
