# Call resolution and call graph — MF023

Calls are resolved by the primary key defined by the architecture:

1. function name;
2. receiver type;
3. ordered positional argument types.

A successful call publishes a `NodeId -> FunctionId` side-table entry. Calls
inside user functions add deterministic graph edges; stable Kahn ordering
produces a topological function order. Any cycle is diagnosed as unsupported
recursion in Nebo v0.1.

Return inference follows the function body facts supplied by the semantic
pipeline: no explicit return means `Void`, identical return types infer that
type, inconsistent returns are rejected, and a value-returning function may
not fall through. Binding a `Void` call result is also rejected.

Behavior-based overload selection, effects, nested functions and recursion are
not supported by this front.
