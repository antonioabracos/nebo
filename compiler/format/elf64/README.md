# ELF64 Format Adapter v0

Emits the deterministic `_start` wrapper, entry symbol and runtime-exit dependency for NASM/GNU `ld`. The adapter consumes the existing TargetContext, ArchitectureBackend and AssemblyWriter.

## MF036 final entry symbol

The ELF64 entry symbol is `_start`. It loads the deterministic internal symbol `nebo_fn_1` and transfers control through `nebo_runtime_start`; the language-level entry remains `start()`.
