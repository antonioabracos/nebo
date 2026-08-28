# Nebo 1.0.1

Nebo 1.0.1 is a corrective maintenance release of the Nebo native compiler and runtime. The compiler and runtime are implemented in x86-64 Assembly and produce static ELF64 executables for the documented Linux System V AMD64 profile. This repository is the sanitized public source snapshot associated with the `nebo-v1.0.1` release.

Nebo 1.0.0 remains preserved as the first stable public release. Version 1.0.1 keeps the Edition, target, public API, public ABI and `.ni` surface unchanged.

The 1.0 claim is deliberately narrow: one certified target, an offline source build, explicit integrity material, and factual maturity labels. A source file, Assembly routine, descriptor or documentation page does not by itself promote a feature to the stable language surface.

## Status and release identity

| Field | Value |
|---|---|
| Version | `1.0.1` |
| Edition | `1.0` |
| Public branch | `main` |
| Release tag | `nebo-v1.0.1` |
| Source identity | Resolved by the annotated public release tag |
| Supported target | `x86_64-systemv-elf-linux` |
| Latest release | [Nebo 1.0.1 release](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.1) |
| Previous release | [Nebo 1.0.0 release](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.0) |
| Compare | [Nebo 1.0.0...1.0.1](https://github.com/antonioabracos/nebo/compare/nebo-v1.0.0...nebo-v1.0.1) |

The release is final rather than a prerelease. The annotated tags remain attached to their respective public source commits. The repository exposes only sanitized public history.

## Fixed in 1.0.1

- Whole-program materialization no longer selects the dedicated Buffer route merely because `Buffer.withCapacity` appears in a mixed source file; this prevents a false-GREEN empty `start()` body.
- `Console.scan()` now composes correctly with an explicit return in the same program.
- Seven compiler call sites introduced with the corrective path now satisfy the System V AMD64 pre-call stack-alignment contract.
- Permanent regression fixtures cover eight false-GREEN scenarios and the seven corrected stack-alignment call sites.

## Project overview

Nebo is a native compiler project whose public 1.0 pipeline reads Nebo source, performs lexical, syntactic and semantic analysis, lowers verified structures, emits deterministic NASM Intel syntax, assembles objects with NASM and links a static ELF executable with GNU `ld`. The repository also contains the native runtime, target metadata and the build graph used to produce `build/bin/neboc`.

The public distribution is offline-first. Its checked-in inputs are enough to build the supported compiler when the documented host tools are already installed. Package registry publication and dependency download are outside the 1.0 release contract.

## Why Nebo exists and design principles

Nebo explores a value-first source model while keeping the resulting native pipeline inspectable. Its governing principles are explicitness, bounded behavior, deterministic artifacts, failure atomicity, capability-aware effects and truthful maturity reporting. Receiver-first operations such as `value.console()` and value-first declarations such as `100.number;` make data flow visible at the source level.

The project separates four questions that are easy to conflate: whether a native ABI exists, whether public source syntax exists, whether features compose through the public compiler, and whether a live environment has been demonstrated. Nebo 1.0 only makes a public claim when the relevant layer is materially verified.

## Supported platform and target matrix

| Platform or target | 1.0 status | Boundary |
|---|---|---|
| Linux x86-64, System V AMD64 ABI, ELF64 | STABLE_1_0 | Certified compiler, runtime and static output profile. |
| Linux x86-64 with environment-specific services | ENVIRONMENT_GATED | Requires the named capability and a factual live environment. |
| AArch64 | NOT_INCLUDED_IN_PUBLIC_1_0 | No certified backend, linker path and target conformance set. |
| WebAssembly | NOT_INCLUDED_IN_PUBLIC_1_0 | No certified 1.0 backend. |
| Windows | NOT_INCLUDED_IN_PUBLIC_1_0 | No certified 1.0 platform path. |
| macOS | NOT_INCLUDED_IN_PUBLIC_1_0 | No certified 1.0 platform path. |

`TOOLCHAIN.json` and `targets/linux-x86_64.json` are the machine-readable target authorities. Other architecture-related source files or descriptors are not support declarations.

## Toolchain requirements

The verified host toolchain is Python 3, Ninja 1.11.1, NASM 2.16.01, GNU `ld` 2.42 and standard ELF inspection utilities. No C compiler is required, no libc is linked into the supported compiler product, and the documented build entry point performs no network operation.

Versions newer than the recorded tools may work, but they are not silently substituted into the 1.0 reproducibility claim. Inspect [TOOLCHAIN.json](TOOLCHAIN.json) before reproducing a build.

## Quick start from source

Run the following in a clean directory on the supported host:

```bash
git clone --branch nebo-v1.0.1 --depth 1 https://github.com/antonioabracos/nebo.git
cd nebo
./scripts/build-neboc.sh
./build/bin/neboc --version
```

The expected final line is `neboc 1.0.1`. The build script delegates to the checked-in Ninja graph and does not download dependencies.

## Quick start with the SDK

Download the SDK tar from the release page, place it in an otherwise clean directory, and use a caller-owned prefix:

```bash
tar -xf nebo-1.0.1-sdk-linux-x86_64.tar
python3 nebo-sdk/install-nebo-sdk.py install nebo-sdk "$PWD/.nebo-sdk"
python3 nebo-sdk/install-nebo-sdk.py verify "$PWD/.nebo-sdk"
"$PWD/.nebo-sdk/bin/neboc" --version
python3 nebo-sdk/install-nebo-sdk.py uninstall "$PWD/.nebo-sdk"
```

Installation is manifest-driven and non-root. Verification rejects altered or unmanifested components, and uninstall removes only paths owned by the install manifest. Set `PYTHONDONTWRITEBYTECODE=1` when inspecting an unpacked bundle in place so Python cache files do not change the bundle being verified.

## Artefact and checksum verification

Verify repository files before building:

```bash
sha256sum -c SHA256SUMS
```

For downloaded release assets, use the `NEBO-1.0.1-SHA256SUMS` asset associated with this exact release. Do not mix checksum files across archives or releases. The release also publishes source, SDK, documentation and tooling manifests, provenance, an SBOM, compatibility identity and the final public seal.

## CLI overview and command table

The live `neboc --help` surface is authoritative. The core compilation commands are `check`, `emit-asm` and `build`; `--help` and `--version` are stable discovery operations.

| Command | Public 1.0 role |
|---|---|
| `neboc check <file.no>` | Validate source without invoking NASM or the linker. |
| `neboc emit-asm <file.no> -o <file.asm>` | Emit deterministic NASM Intel assembly. |
| `neboc build <file.no> -o <artifact>` | Produce a native ELF64 executable. |
| `neboc bench numeric` | Run the bounded local numeric benchmark. |
| `neboc warnings --list` | List stable warning groups and defaults. |
| `neboc diagnostic-schema --version 1` | Report the machine-diagnostic schema. |
| `neboc explain <diagnostic-code>` | Read a versioned offline diagnostic explanation. |
| `neboc diagnostics --search <term>` | Search the bounded offline diagnostic catalog. |
| `neboc exit-codes` | List the stable process-exit contract. |
| `neboc bootstrap --verify` | Verify factual stage0 and source-compiler availability. |
| `neboc protocol generate|fuzz <schema>` | Operate on bounded typed protocol artifacts. |
| `neboc optimize-explain <file>` | Report bounded optimization facts. |
| `neboc probabilistic-report <artifact>` | Inspect a redacted, versioned probabilistic artifact. |
| `neboc firmware build|test ...` | Simulator-only reference-board contract. |
| `neboc simulation-replay <log>` | Validate and replay a bounded versioned simulation log. |
| `neboc crypto-audit <artifact>` | Inspect crypto metadata without reading secret bytes. |
| `neboc bug-report ...`, `minimize-ice` | Create, inspect or minimize redacted local failure bundles. |

Some offline documents describe additional tooling contracts. They are not additional live commands unless they appear in the compiler's current `--help` output.

## First Nebo program

Save this validated source as `hello.no`:

```nebo
start() {
    "Hello from Nebo 1.0".console();
}
```

Run `build/bin/neboc check hello.no`, then `build/bin/neboc build hello.no -o hello` and `./hello`. The current headless profile validates and runs this program successfully; visible presentation remains dependent on the console route and environment rather than being inferred from source spelling alone.

## Source files, `start()` and `console`

Public examples use `.no` source files and define `start()` as the program entry. Statements are semicolon-terminated. `console()` is the canonical receiver-first output primitive; `.print()` is not introduced as an alias. A terminal expression may be evaluated without becoming the operating-system process exit status.

Console routing includes default, named-independent and headless concepts in the implementation. Nebo 1.0 documents the default source form and keeps live display behavior environment-gated.

## Value-first declarations and explicit or implicit type forms

Nebo declarations place the value before the binding name. This validated example introduces an inferred integer binding and then uses it as the receiver of `console()`:

```nebo
start() {
    100.number;
    number.console();
}
```

Explicit forms use the canonical type syntax documented by the versioned language reference. Inference never licenses a second initialization of an immutable binding, and examples should be checked by the current compiler rather than reconstructed from historical proposals.

## Primitive and built-in types

The stable family inventory includes `Int`, `Bool`, `Void`, `Text`, `Char`, `Bytes`, `Option`, `Result` and `Error`. Bounded floating-point, arrays, ranges, slices, formatting plans and structured-format descriptors carry target or maturity qualifiers. `Text`, `Char` and `Bytes` are distinct: UTF-8 validity, scalar boundaries and raw byte operations are not interchangeable contracts.

Nominal and generic identity exists within the documented compiler bounds. A type or layout routine in Assembly is not, by itself, proof that every related constructor or operator is active public syntax.

## Bindings, constants, mutability and assignment

Bindings are value-first and immutable unless the explicit current syntax and semantic rules grant mutation. Assignment is checked against binding identity, initialization state and type; compound integer `+=` and `-=` are active within the certified profile. Duplicate initialization, mutation of immutable values, dynamic binding names and use before definite initialization are rejected.

Constants and compile-time values remain bounded by source size, nesting, numeric and diagnostic limits. The compiler preserves failure atomicity: a failed validation must not publish a partial output artifact.

## Expressions, operators and control flow

The active core covers grouping, calls, blocks, arithmetic precedence, integer remainder, unary integer negation, boolean negation, `&&`, `||`, integer ordering, bounded equality, assignment and bounded result propagation. Integer and floating arithmetic do not share an unlimited claim: floating operations are target-gated. Historical Unicode aliases and many mathematical symbols remain outside public 1.0 syntax.

Control flow includes the materially documented statement and branch forms. Loops, breaks, continues and returns are validated for reachability, initialization and cleanup. Treat the offline language reference and compiler diagnostics as the exact authority for a given construct.

## Functions, calls and modules

Functions have explicit declaration, parameter, call-resolution and lowering stages. Receiver-style calls and bounded generics are resolved semantically; overload choice, type constraints and ownership are not dispatched from filenames or test fixtures. Calls must satisfy arity, parameter modes and return contracts.

Static multi-unit composition uses repeated `--unit <file.no>` arguments on `check`, `emit-asm` and `build`. The module graph is bounded and cycle-checked. This is local static composition, not a package-registry or dynamic-loading claim.

## Imports, interfaces and initialization

The source-module and compiled-interface components are target-gated. Imports identify modules; they do not grant capabilities. Visibility, interface schema, duplicate exports, graph integrity and initialization ordering are checked before code publication. Effectful initialization can be denied by policy.

Nebo 1.0 has a small implicit prelude and a bounded no-prelude profile in the documentation authority. Generated or compiled interfaces remain versioned artifacts and must not be treated as arbitrary trusted input.

## Ownership, move, copy, clone, borrow and drop

Ownership operations are tracked semantically before lowering. Scalar copies, explicit moves, bounded clones, shared borrows, unique borrows, lexical release and cleanup are distinct transitions. The implementation rejects use after move or release, incompatible aliasing, borrow escape, double drop and owner access during an exclusive borrow.

Cleanup is attached to normal and non-local exits. The public claim is bounded to constructs exercised by the current compiler; native ownership helpers do not make every possible lifetime feature part of source 1.0.

## Effects, capabilities and resource boundaries

Capabilities are deny-by-default and explicit. Importing a module never grants a capability. Filesystem, process, network, clock, randomness, display, model, media, hardware, crypto and agent execution are separately classified. Policy checks occur before lowering or runtime work, and sensitive fields must be redacted before diagnostics, logs or audit sinks.

An in-process policy or subprocess boundary is not described as a strong operating-system sandbox. Environment-gated capabilities require a live proof in the intended environment.

## `Option`, `Result`, `Error` and diagnostics

`Option`, `Result` and `Error` are stable symbol families, with matching and result propagation represented explicitly. Propagation validates the enclosing return type and preserves the typed success or error path. It is not an untyped shortcut.

Diagnostics support human, short, JSON, JSON-lines and SARIF-oriented modes through the public `check` options. Width, color, path style, maximum error count, fail-fast or keep-going behavior and fix display are bounded. Invalid source must return nonzero and must not leave a partial artifact.

## Collections and data structures

Array, Range and Slice are target-gated 1.0 families. Bounds, literal arity, direction, step, ownership and view lifetime are checked. Dataset, Table, Row, Column and Stream are contract-only descriptors rather than stable collection promises.

The following table covers every public Standard Library module in the frozen documentation inventory. Maturity labels are intentionally conservative.

| domain | surface | summary | maturity | supported target | required capability | external dependency | documentation source | public source path |
|---|---|---|---|---|---|---|---|---|
| Standard Library | `std.collections` | Array, Range and Slice surfaces within target bounds. | TARGET_GATED | `x86_64-systemv-elf-linux` | `NONE_BY_IMPORT` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.concurrency` | Task, future, channel and cancellation contracts. | CONTRACT_ONLY | `x86_64-systemv-elf-linux` | `Concurrency` | capability-specific local environment | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.core` | Core scalar values, functions and protocol dispatch. | STABLE_1_0 | `x86_64-systemv-elf-linux` | `NONE_BY_IMPORT` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.data` | Dataset, table, row, column and stream descriptors. | CONTRACT_ONLY | `x86_64-systemv-elf-linux` | `NONE` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.format` | Formatting plans and templates. | TARGET_GATED | `x86_64-systemv-elf-linux` | `NONE` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.formats.toml` | TOML descriptor contract. | CONTRACT_ONLY | `x86_64-systemv-elf-linux` | `NONE` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.formats` | Bounded CSV, JSON, JSONL, Markdown and TSV descriptors. | TARGET_GATED | `x86_64-systemv-elf-linux` | `NONE` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.net` | Loopback-only network descriptor contracts. | CONTRACT_ONLY | `x86_64-systemv-elf-linux` | `NETWORK_EXPLICIT` | live loopback environment | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.pattern` | Pattern and regular-expression contracts. | CONTRACT_ONLY | `x86_64-systemv-elf-linux` | `NONE` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.prelude` | Small implicit prelude profile; import does not grant capabilities. | TARGET_GATED | `x86_64-systemv-elf-linux` | `NONE_BY_IMPORT` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.random` | Bounded random-value contract. | CONTRACT_ONLY | `x86_64-systemv-elf-linux` | `Random` | capability-specific local environment | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.result` | Option, Result, Error, matching and propagation contracts. | STABLE_1_0 | `x86_64-systemv-elf-linux` | `NONE_BY_IMPORT` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.sync` | Lock and deadline contracts. | CONTRACT_ONLY | `x86_64-systemv-elf-linux` | `Concurrency` | capability-specific local environment | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.system.fs` | Path queries and bounded filesystem contracts. | TARGET_GATED | `x86_64-systemv-elf-linux` | `FileSystem` | capability-specific local environment | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.system.process` | Bounded process substrate. | CONTRACT_ONLY | `x86_64-systemv-elf-linux` | `Process` | capability-specific local environment | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.system` | System services behind explicit capabilities. | TARGET_GATED | `x86_64-systemv-elf-linux` | `EXPLICIT` | capability-specific local environment | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.text` | Text, Char, Bytes and bounded UTF-8 behavior. | STABLE_1_0 | `x86_64-systemv-elf-linux` | `NONE_BY_IMPORT` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.time` | Bounded clock contracts. | CONTRACT_ONLY | `x86_64-systemv-elf-linux` | `Clock` | capability-specific local environment | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |
| Standard Library | `std.validation` | Bounded validation combinators. | TARGET_GATED | `x86_64-systemv-elf-linux` | `NONE` | none | [offline 1.0 docs](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar) | [`compiler/stdlib`](compiler/stdlib) |

### Public Standard Library symbol-family index

| module | public symbol family | maturity | summary boundary |
|---|---|---|---|
| `std.core` | `Bool` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.core` | `functions` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.core` | `generic and nominal identity` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.core` | `Int` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.core` | `protocol dispatch` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.core` | `Void` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.result` | `Error` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.result` | `match` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.result` | `Option` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.result` | `propagation` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.result` | `Result` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.validation` | `validation combinators` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.format` | `FormatPlan` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.format` | `templates` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.pattern` | `regex and patterns` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.text` | `Bytes` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.text` | `Char` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.text` | `Text` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.text` | `UTF-8` | STABLE_1_0 | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.collections` | `Array` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.collections` | `Range` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.collections` | `Slice` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.data` | `Column` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.data` | `Dataset` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.data` | `Row` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.data` | `Stream` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.data` | `Table` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.formats.toml` | `TOML` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.formats` | `CSV` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.formats` | `JSON` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.formats` | `JSONL` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.formats` | `Markdown` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.formats` | `TSV` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.net` | `loopback ports only` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.random` | `bounded random` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.system.fs` | `path query and bounded filesystem` | TARGET_GATED | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.system.process` | `bounded process substrate` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.time` | `bounded clocks` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.concurrency` | `cancellation` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.concurrency` | `channels` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.concurrency` | `futures` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.concurrency` | `tasks` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.sync` | `deadlines` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |
| `std.sync` | `locks` | CONTRACT_ONLY | Listed at family level; consult the versioned offline reference for exact signatures and bounds. |

## Text, bytes, Unicode, formatting and scan

`Text`, `Char`, `Bytes` and UTF-8 are stable families. Text operations preserve UTF-8 boundaries; byte operations preserve raw length and values; a character represents a bounded scalar rather than an arbitrary byte. Invalid encodings and malformed source produce typed diagnostics.

Formatting plans, templates and structured formats are target-gated or contract-only as labeled in the module inventory. `scan()` belongs to the console/input model but live input behavior is environment-dependent. Never infer terminal, locale or Unicode-normalization behavior beyond the documented profile.

## Files, system, networking and concurrency

Filesystem path queries and bounded filesystem behavior are target-gated behind `FileSystem`. Process work is contract-only behind `Process`. Networking is restricted to explicitly modeled, experimental loopback-port contracts; arbitrary external network access is not a public 1.0 claim. Clock and random services are contract-only behind their capabilities.

Tasks, futures, channels, cancellation, locks and deadlines are documented as contract-only concurrency surfaces. Their presence in the source tree does not promote them to stable syntax or a production scheduler guarantee.

## Numeric, math, matrices, tensors and scientific domains

Stable arithmetic is centered on bounded scalar operations in the certified target. Floating operations and equality have narrower target gates. Math quantities, angles, ratios, roots and constants are target-gated documentation surfaces; number theory, probability, statistics, calculus, matrices and tensors are contract-only domain surfaces.

The repository includes native kernels and domain-related substrates. They are implementation material, not a blanket public numerical-computing claim. There is no certified accelerator, distributed numerical runtime, automatic-differentiation system or second numeric target in 1.0.

## Console, color, visualization and observability

Minimal Console source composition is stable for the supported target, while live X11 display behavior is environment-gated. Software visualization summaries are bounded; charts, dashboards and render plans are contract-only. Color and presentation must therefore be treated as output-environment concerns rather than guaranteed byte sequences.

Observability follows redaction and bounded-record rules. Diagnostic output may expose safe source context, but credentials, private keys, sensitive payloads and private local paths are not valid telemetry content.

## Packages, tooling, editor and offline docs

The SDK carries the compiler, runtime object, installer, formatter, linter, LSP adapter, project scaffold helper, refactor helper, doctor, completion files, editor metadata, diagnostic catalog, interface inventory and offline documentation. Those files are manifest-bound and can be verified without network access.

Package resolution is offline and lockfile-oriented in the documented tooling model. Nebo 1.0 publishes no package-registry entry and makes no signing-key claim. The complete versioned documentation is available as the [offline documentation asset](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar).

## Compiler architecture and source-to-ELF pipeline

The source pipeline is organized as source loading and UTF-8 validation, lexing, AST construction, parsing, semantic scopes and symbols, type checking, dependency and control analysis, lowering, deterministic Assembly writing, x86-64 code generation, NASM assembly and GNU `ld` linking. Diagnostics and target context cross the stages without replacing semantic decisions with source-string dispatch.

The public tree keeps the compiler under [`compiler`](compiler), the runtime under [`runtime`](runtime), the supported build entry point under [`scripts/build-neboc.sh`](scripts/build-neboc.sh), and the factual graph in [`build.ninja`](build.ninja).

## Runtime, ABI and target details

The supported output is ELF64 for x86-64 System V. Calls observe the AMD64 ABI, including stack alignment at external boundaries. The runtime core and compiler product are statically linked in the verified profile, with no ELF interpreter and no dynamic `NEEDED` entries for libc.

Target metadata records the architecture, object format and toolchain expectations. ABI helpers, target adapters and runtime services remain implementation layers; they do not independently define source syntax.

## Determinism, reproducibility and failure atomicity

`emit-asm` is deterministic for the validated inputs and environment. Repository and release checksums make byte identity explicit. Reproducibility uses fixed source identity, declared host tools, locale and time-zone controls, and clean roots rather than timestamps or network-fetched dependencies.

Checks and failed builds must not publish partial artifacts. SDK installation stages and verifies content before activation; verification detects altered or extra bundle components; uninstall follows the ownership manifest. These properties are bounded to the documented workflow, not a universal guarantee for every filesystem or host failure.

## Security and supply-chain model

Treat source, package files, interfaces, plugin descriptors and capability inputs as untrusted. Nebo applies typed bounds, deny-by-default capabilities, path confinement, digest verification, provenance, third-party notices and redaction before sinks. The public source and assets were checked for credentials, private keys, live tokens and private local paths.

The release is unsigned and makes no key-distribution or signature-verification claim. Dynamic FFI, arbitrary external networking, strong OS sandboxing and independent security certification are outside the public 1.0 claim.

## Repository layout

| Path | Purpose |
|---|---|
| `compiler/driver` | CLI and compiler orchestration entry points. |
| `compiler/lexer`, `compiler/parser`, `compiler/ast` | Front-end construction and recovery. |
| `compiler/semantic` | Symbols, types, modules, effects, ownership and validation. |
| `compiler/lowering` | Verified lowering plans and native contracts. |
| `compiler/codegen` | x86-64 and assembly emission. |
| `compiler/format` | ELF64 format adapter. |
| `compiler/target`, `compiler/toolchain` | Target and host-tool descriptions. |
| `runtime/` | Native runtime, kernels and bounded services. |
| `scripts/build-neboc.sh` | Offline source build entry point. |
| `build.ninja` | Factual build graph. |
| `version/`, `targets/` | Version and supported-target metadata. |

Generated build outputs are not source authorities and should not be committed as replacements for the checked-in graph.

## Release assets

The release has 29 assets: four payload archives plus compatibility, lifecycle, upgrade, support, provenance, SBOM, package, checksum and verification metadata. The payload and descriptive metadata are bound by the release checksum manifest, and the public seal binds that manifest to the public source commit, tree and annotated tag.

Use the [Nebo 1.0.1 release page](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.1) as the current asset index. Asset names, sizes and SHA-256 digests belong to this exact release; download counters are not integrity fields. The [Nebo 1.0.0 release page](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.0) remains available with its original assets.

## Compatibility, editions and migration

The compiler identifies as 1.0.1. The bounded compatibility model recognizes legacy language edition 1 and current edition 2, with ABI version 0 and runtime version 0. Packages must stay within declared edition and ABI ranges. Unsafe or breaking migrations are reported rather than silently rewritten.

Before migrating, preserve source, lock data and expected outputs; validate the unchanged project; apply only explicit mechanical steps; then repeat checks, deterministic assembly generation, native build and project tests. The release tag remains the source identity for 1.0 even if `main` later advances for documentation.

## Known limitations and non-claims

- Only `x86_64-systemv-elf-linux` is certified.
- NASM and GNU `ld` remain external stage0 tools; the compiler is not claimed to be self-hosting.
- No package registry is published.
- No external-user adoption claim is made by the validation set.
- Experimental and contract-only modules are not stable APIs.
- X11, filesystem, process and other live services require their environment and capability.
- Dynamic FFI, arbitrary remote networking, signing keys, a strong OS sandbox, independent security certification and additional certified operating systems are not claimed.
- A native routine, descriptor or historical document is not proof of active public syntax.

These boundaries are part of the release contract rather than hidden omissions.

## Troubleshooting

If the source build fails, first compare Python, Ninja, NASM and GNU `ld` versions with `TOOLCHAIN.json`; then run the build from a clean tag checkout. If `check` rejects a program, use a bounded message format, `neboc explain <code>` and the offline diagnostic catalog. If deterministic output differs, compare source identity, locale, time zone, tool versions and command arguments.

For SDK failures, verify the downloaded tar digest, unpack into a clean directory and avoid writing Python cache files into the source bundle. Verification intentionally rejects unmanifested components. For runtime failures, confirm ELF architecture, static linkage and the certified host profile before investigating environment-gated services.

## Support and contribution expectations

Security issues should be reported privately to the maintainer with the affected public commit, target, minimal reproducer and impact; never include real credentials or personal data. For compiler defects, include the `neboc --version` result, exact command, source minimization, expected behavior and safe diagnostic output.

Public visibility does not imply that patches, feature requests, redistribution or derivative publication are accepted. Contribution and usage permissions remain subject to the repository's governing terms and explicit maintainer decisions.

## License and usage rights

Copyright © 2026 António José Martins Abraços. All rights reserved.

The repository is publicly viewable. Usage rights are governed by [LICENSE](LICENSE); public visibility does not itself grant additional rights to copy, modify, distribute, sublicense, publish, sell or otherwise use the software or documentation. The current license text also describes the repository as private, which is presentation wording inconsistent with the current public visibility. This README does not change or reinterpret the legal terms; that wording requires a separate decision by the rights holder.

## Provenance and acknowledgements

[`SOURCE-PROVENANCE.json`](SOURCE-PROVENANCE.json) identifies the public snapshot as version 1.0.1, edition 1.0, tag `nebo-v1.0.1` and the supported target. [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md) records third-party and host-tool notices. [`SHA256SUMS`](SHA256SUMS) binds the repository files.

Nebo's verified toolchain relies on Python, Ninja, NASM, GNU Binutils and standard ELF inspection utilities. Their presence as external build tools is disclosed and does not turn them into bundled runtime dependencies.

## Documentation index

- [Source distribution entry point](README_SOURCE.md)
- [Compiler architecture and implementation notes](compiler/README.md)
- [CLI implementation notes](compiler/driver/cli/README.md)
- [Toolchain metadata](TOOLCHAIN.json)
- [Target descriptor](targets/linux-x86_64.json)
- [Version metadata](version/NEBO-VERSION.json)
- [Source provenance](SOURCE-PROVENANCE.json)
- [Third-party notices](THIRD-PARTY-NOTICES.md)
- [Repository checksums](SHA256SUMS)
- [License](LICENSE)
- [Nebo 1.0.1 public release](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.1)
- [Nebo 1.0.0 preserved release](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.0)
- [Compare Nebo 1.0.0...1.0.1](https://github.com/antonioabracos/nebo/compare/nebo-v1.0.0...nebo-v1.0.1)
- [Complete offline 1.0.1 documentation](https://github.com/antonioabracos/nebo/releases/download/nebo-v1.0.1/nebo-1.0.1-docs-offline.tar)

The offline documentation asset contains the complete versioned language, core, prelude, Standard Library, diagnostics, tutorial, cookbook, examples and troubleshooting corpus. The root README remains self-contained enough to build, verify and understand the supported boundary even when the offline asset has not been unpacked.
