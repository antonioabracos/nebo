# Nebo CLI driver

MF035 materializes the public `neboc` command surface:

```txt
neboc --help
neboc --version
neboc check <file.no>
neboc emit-asm <file.no> -o <file.asm>
neboc build <file.no> -o <artifact> [--keep-temp]
```

The CLI performs deterministic argument parsing, loads the source, runs the
existing lexer and parser gate, and consumes the frozen target, codegen, format
and toolchain contracts. `check` never invokes NASM or GNU `ld`.

`run`, package commands and a REPL are not part of MF035.

MF037 keeps the public commands unchanged while `emit-asm` and `build` now lower real Int/Bool expression statements from the parser AST.

RF46-G37-F07 adds `probabilistic-report <artifact>` for a fixed 64-byte,
redacted `NBPRB001` artifact. The command authenticates its versioned metadata
locally and emits only model/inference identifiers, seed, diagnostic status,
provenance digest and the redaction state; it never emits raw observations.

## MF037-R2 start-body materialization

The top-level parser deliberately preserves function and `start()` bodies as opaque lexical blocks. The public CLI now materializes the unique `start()` body through the existing MF018 StatementRequest/Pratt parser after the top-level parse succeeds and before code generation. The original parser contract remains unchanged; only the compilation-session AST links `StartDecl.first_child` to the parsed block consumed by MF037 value codegen.
