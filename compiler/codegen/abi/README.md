# ABI Adapter

The MF033 ABI Adapter translates frozen Nebo function signatures to the physical
DG-005 x86-64 calling convention. The first implementation is in `x86_64/` and
is selected only through the already validated MF031 TargetContext and MF032
ArchitectureBackend.

The adapter emits deterministic NASM Intel text into the MF032 AssemblyWriter.
It does not own memory, implement the runtime, package ELF objects or invoke the
assembler/linker.
