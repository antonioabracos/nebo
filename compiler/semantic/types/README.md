# MF022 — fundamental types

`TypeId` is a stable 1-based index into an immutable caller-backed `TypeTable`.
The v0.1 built-in order is frozen as `Void`, `Bool`, `Int`, `Text`, `Console`
and `Pending<Text>`. No pointer identity, implicit coercion, Float, collections,
user-defined types, signatures or code generation is introduced in MF022.
