# G03-PF005 vertical numeric-safety fixtures

This corpus is the first public vertical integration of `Int.toFloat()` and the
four frozen `Float` classifiers. Positive sources must pass `check`,
`emit-asm`, `build` and native execution. Negative sources promote the nine
G03-PF002 diagnostic contracts. Float→Int, casts, aliases, implicit coercion,
wrapping and saturation remain unavailable.
