# TargetContext v0

MF031 materializes the single approved target tuple:

```txt
x86_64-systemv-elf-linux
```

The context keeps ISA, external ABI, object format, operating environment,
`DataLayout`, runtime profiles, toolchain profile, features and capabilities
separate. Incomplete or unsupported combinations fail explicitly. Host state is
not embedded in the target record.

`neboc_target_context_validate` recomputes the pointer-free tuple hash over the
first 40 bytes, validates the referenced `DataLayout` canonically and only then
compares the reflected layout hash. Mirrored corruption is therefore rejected.

MF032 remains responsible for the Architecture Backend and Assembly writer.
