# MF034 ToolchainDescriptor

The descriptor freezes the first toolchain as explicit NASM and GNU `ld` paths. It creates structured argv vectors and delegates execution to a versioned process callback. There is no shell command string, no `sh -c`, no C compiler and no libc fallback. Paths with spaces remain one argv atom; leading-dash artifact paths, embedded NUL and newlines are rejected.


MF036 tightens deterministic native linking: the canonical GNU `ld` argv includes `-x` after `--build-id=none`. This discards local symbols, including NASM `STT_FILE` names derived from output-specific temporary `.asm` paths, while preserving the required global Nebo/runtime symbols.
