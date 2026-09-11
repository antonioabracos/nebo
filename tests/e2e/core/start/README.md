# MF036 empty start end-to-end fixture

This fixture freezes the first public native program:

```nebo
start() {
}
```

The language entry is `start()`. The internal deterministic symbol is `nebo_fn_1`, the ELF64 process entry is `_start`, and the runtime bridge is `nebo_runtime_start`. Successful execution produces no stdout/stderr and exits with status `0`.
