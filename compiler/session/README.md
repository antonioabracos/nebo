# CompilationSession v0

`CompilationSession` is the explicit root of one compiler invocation.

```txt
CompilationSession
├── HostServices pointer
├── owner token and generation
├── normative phase
├── StatusCode and run state
├── approved resource limits
├── deterministic statistics
├── MemoryRegion
├── Arena
├── StringPool
└── minimal diagnostic-count seam
```

v0.1 compiles one source file per session. MF010 does not load source, create a
parser, or introduce a logging framework.

A blocking failure finalizes the diagnostic seam and invokes central cleanup.
Cleanup is idempotent and releases Arena/MemoryRegion ownership in order.
