# MF024 Effect Semantics

Effects are deterministic semantic classifications: `PURE`, `CONSOLE_EFFECT`,
`SCAN_EFFECT`, and their explicit combined form. Wrapper functions inherit
callee effects. A function marked thread-capable must carry console and/or scan
effect; ordinary pure functions cannot opt into thread capability.
