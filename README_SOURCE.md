# Nebo 1.0.0 source distribution

This offline archive contains the Assembly compiler/runtime sources and the
factual Ninja build graph for Linux x86-64. Build with:

```sh
./scripts/build-neboc.sh
```

Required local tools are Python 3, Ninja, NASM, GNU ld and standard ELF
inspection utilities. The build entrypoint performs no network operation.
