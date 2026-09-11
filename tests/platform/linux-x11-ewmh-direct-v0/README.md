# MF051 — linux-x11-ewmh-direct-v0 tests

`mf051_platform_adapter_test.asm` contains five primary scenarios:

1. required capability report and certification;
2. X11-to-common normalized event bridge;
3. opaque generational handles with zero native-ID leakage;
4. live direct X11/XWayland empty-window and BGRA8 presentation smoke;
5. explicit refusal when a required capability is missing.

The live scenario receives an AF_UNIX socket path and MIT-MAGIC-COOKIE-1 value from the validation harness. The binary itself links no Xlib, toolkit, C runtime or libc.
