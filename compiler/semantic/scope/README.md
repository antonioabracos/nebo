# ScopeTable — MF021

The name-resolution phase owns explicit lexical scopes with stable 1-based
`ScopeId` values. Scope entries store only structural IDs and counters; no
source, AST or allocation pointer is persisted as semantic identity.

MF021 creates start, function, if-block and else-block scopes. Nested value
shadowing is forbidden. Modules and type scopes are outside this front.
