# FunctionTable — MF023

MF023 introduces a caller-backed immutable table of receiver-first function
signatures. `FunctionId` values are deterministic 1-based source-order indices;
pointer identity is never part of the semantic contract.

Each signature records the declaration token, receiver `TypeId`, ordered
positional `TypeId` slice, inferred return `TypeId`, declaration `NodeId`, and
function `SymbolId`. The table owns no heap storage and freezes with a stable
FNV-1a hash.

Nested functions, behaviors, effects, intrinsics materialization and backend
lowering are outside MF023.
