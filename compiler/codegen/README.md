# Code generation

MF032 contains the first target-selected code generation boundary. The core is
split between the x86-64 `ArchitectureBackend`, the target-neutral text
`AssemblyWriter`, and stable codegen diagnostics. No runtime, object writer or
linker driver is implemented here.
