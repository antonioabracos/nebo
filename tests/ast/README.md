# MF020 AST tests

The MF020 suite freezes parser output into an immutable caller-backed
`AstStore`, validates 1-based `NodeId` links, emits a canonical address-free
dump and checks the before/after hash contract.

The internal fuzz scenario enumerates every Core v0.1 token kind in a bounded,
deterministic two-token corpus. It proves termination and bounded outputs; it
is not a replacement for later semantic or end-to-end fuzzing.
