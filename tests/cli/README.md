# MF035 CLI tests

The suite exercises the real `build/bin/neboc` process and the public commands
`check`, `emit-asm` and `build`. Fixtures are synthetic and contain no user data.

`check` must not create toolchain artefacts. `emit-asm` must match the canonical
NASM golden. `build` must create a static ELF64 executable and remove temporary
files unless `--keep-temp` is present.

MF035 does not execute the produced application. MF036 owns the first empty `start()` native execution proof.

MF037 updates the minimal Assembly golden with stable Runtime Core trap externs; the empty program binary remains behaviorally unchanged.
