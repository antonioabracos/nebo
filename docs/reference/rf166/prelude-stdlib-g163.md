# Prelude and standard-library visibility

Edition 1 owns one authenticated `std.prelude` interface. The interface is
small: `Option`, `Result`, `Error`, `Ordering`, `Range`, the `Eq`, `Ord`,
`Iterator`, and `IntoIterator` protocols, plus the minimal `console` and `scan`
methods. Each injected record has an origin-qualified `SymbolId`; injection is
staged so a collision publishes no partial resolver state.

## Commands

```text
neboc check <source> --no-prelude [--edition 1]
neboc emit-asm <source> --no-prelude -o <output.asm> [--edition 1]
neboc build <source> --no-prelude -o <output.elf> [--edition 1]
neboc prelude-report [--edition 1] [--source <source>] [--no-prelude]
neboc migrate-imports <source>... --edition 1 --profile default|no-prelude --preview|--apply
neboc stdlib modules [--edition 1]
```

`--no-prelude` creates a freestanding profile. Prelude names then require an
explicit selective import from their owning standard-library module. Wider
modules such as `std.fs`, `std.net`, `std.regex`, `std.scientific`,
`std.devices`, and `std.visual` are never injected. Importing a module exposes
its selected names but does not grant any capability.

Checking, Assembly emission and building use the same visibility decision.
The visibility owner consumes explicit standard-library imports and preserves
their byte positions as whitespace before the native Program parser processes
the remaining statements. Missing imports reject every stage before artifact
publication. Return values and runtime effects come from the native backend.

`prelude-report` binds its observations to manifest digests and, when given a
source, reports used names and reachable components. `stdlib modules` is an
offline, target-qualified projection of the local registry.

## Migration safety

`migrate-imports --profile no-prelude` inserts only imports marked
`neboc:migrate-imports`; the default profile removes only those tool-owned
imports. Preview never writes. Apply checks every planned source revision,
writes same-directory temporary files, and replaces the originals only after
validation. Collisions, duplicate file identities, symlinks, oversized input,
invalid UTF-8, unknown editions, and unsupported targets fail closed.

Round-tripping a source from default to no-prelude and back restores its exact
bytes. User-authored imports are never removed.

## Diagnostics

- `NEBO-RF166-G163-001`: invalid manifest or unsupported edition.
- `NEBO-RF166-G163-002`: an implicit prelude name is hidden by no-prelude.
- `NEBO-RF166-G163-003`: injection or migration collision.
- `NEBO-RF166-G163-004`: a wider stdlib name lacks an explicit import.
- `NEBO-RF166-G163-005`: invalid or unavailable stdlib module/export.
- `NEBO-RF166-G163-006`: invalid, duplicate, or stale migration input.
- `NEBO-RF166-G163-007`: unsafe, oversized, or non-UTF-8 source input.
- `NEBO-RF166-G163-008`: unsupported target.
- `NEBO-RF166-G163-009`: internal admission or publication divergence.

Failures emit no success JSON and do not publish compiler, resolver, lowering,
artifact, or source-edit state.
