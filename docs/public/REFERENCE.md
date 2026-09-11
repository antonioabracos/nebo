# Nebo command reference

The public compiler entry point is `build/bin/neboc`.

```bash
build/bin/neboc --version
build/bin/neboc --help
build/bin/neboc check program.no
build/bin/neboc emit-asm program.no -o program.asm
build/bin/neboc build program.no -o program
build/bin/neboc bench numeric
build/bin/neboc abi-report
build/bin/neboc conformance-manifest --target x86_64-systemv-elf-linux
build/bin/neboc doctor
build/bin/neboc nebo-1.0-readiness
```

`check` performs validation without invoking the external assembler or linker.
`emit-asm` emits deterministic NASM Intel syntax. `build` creates an ELF64
executable and accepts repeated `--unit` inputs for bounded static composition.
`--keep-temp` retains build intermediates when explicitly requested. The
compiler reports version `1.1.0` and target
`x86_64-systemv-elf-linux`. Local publication and tag repair remain separate,
explicitly human-authorized operations.

`abi-report`, `runtime-report`, `compatibility-report`,
`conformance-manifest`, `doctor`, and `security-report` emit canonical JSON.
Release preparation is offline. Materialization is accepted only as a dry-run
below `/tmp`; restore verification compares candidate bytes and publication is
not available through this local conformance surface.
