# MF026 Intrinsic Contracts

`IntrinsicTable` materializes the six v0.1 built-in signatures for
`Text/Int/Bool.console`, `Text.scan`, `Console.scan` and `Color.color`.
Resolution uses receiver, canonical name and positional arity like an ordinary
call. Only after a unique signature match does the table expose explicit effect,
concurrency and runtime-contract metadata. MF026 does not choose a Console route
and does not create runtime objects.
