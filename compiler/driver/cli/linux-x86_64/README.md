# Linux x86-64 CLI adapter

This adapter owns the Linux process-entry argv integration and supplies the minimal
`fork`/`execve`/`wait4` runner/remover callbacks consumed by the MF034
`ToolchainDescriptor`. It does not redefine assembler/linker argv ordering.

Security rules:

- no shell command string;
- every tool argument is one explicit argv atom;
- output and temporary paths are bounded;
- `.no` is the only accepted public source extension;
- partial outputs are removed on failure;
- normal build removes `.neboc.asm` and `.neboc.o`;
- `--keep-temp` preserves those two files only;
- no C or libc dependency.
