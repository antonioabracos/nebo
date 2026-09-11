# MF034 format/runtime/toolchain tests

Scenarios 1–14 correspond one-to-one with the MF034 primary Test IDs. The native binary uses a fake structured-argv process adapter; `verify-native.sh` additionally assembles and links a real ELF64 sample with NASM and GNU `ld` twice.


The linker invocation contract now also checks `argc == 15`, the standalone `-x` argv atom, and `--gc-sections`. This is a deterministic-link requirement, not global stripping: `_start`, `nebo_fn_1`, `nebo_runtime_start` and `nebo_runtime_exit` remain global.
