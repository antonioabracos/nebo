# HostServices v0

`HostServices` is the only Compiler Core boundary for host memory, files,
temporary objects, processes, time, diagnostics and process termination.

```txt
Version: 0
Table size: 144 bytes
Context: adapter-private pointer
Return model: StatusCode + explicit result payload
Core syscalls: forbidden
Core shell strings: forbidden
Process input: argv[] of HostArg
Captured tool output limit: 16 MiB
```

The Linux v0 adapter deliberately advertises only capabilities it implements.
The FakeHost advertises all capabilities and is the normative fault-injection
adapter for compiler tests.
