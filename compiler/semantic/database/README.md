# Semantic database

MF025 closes the target-independent semantic core with caller-owned,
NodeId-indexed side tables. `SemanticDatabase` is an audit/freeze descriptor: it
checks that every explicitly required type, symbol, effect, call, behavior,
control-flow, constant, route and dependency entry exists before the AST may
advance.

The requirement mask is explicit. MF025 consumes route and Pending dependency
IDs only when a caller already supplies them; it does not implement Console
routing, Pending graph construction, lowering, backend IR or runtime behavior.

`ControlFlowTable` and `ConstantValueTable` are mutable during construction and
frozen before the Validated AST audit. Hashes include stable values and IDs only;
pointers are excluded.
