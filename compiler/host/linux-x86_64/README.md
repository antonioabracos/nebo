# Linux x86-64 HostServices v0

Implemented capabilities:

```txt
memory
file
memfd-backed temporary objects
time
diagnostics
process exit
```

`process_spawn` and `process_wait` are present in the versioned table but return
`UNSUPPORTED_TARGET`; the adapter does not advertise the process capability.
Structured process requests and bounded capture are already implemented and
fully tested through FakeHost. Native tool execution remains deferred to its
approved toolchain front.
