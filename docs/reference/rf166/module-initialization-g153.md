# Deterministic module initialization

Nebo's stable module profile treats imported literal constants and metadata as
compile-time facts. Importing a module never executes user code and never grants
an effect or capability. Runtime work must remain an explicit call from the
program's `start` path.

The compiler builds one bounded `ModuleInitPlan` from the native module graph.
Dependencies precede importers, ready-node ties use `ModuleId`, and neither
source import order nor object/linker order changes the plan. The current stable
bound is eight initialization nodes.

`neboc module-init-report ENTRY --unit A --unit B` prints the authenticated
graph snapshot, topological logical names, pure constant count, required
effects/capabilities, and rejected entries. The report host does not parse Nebo;
it joins `module-check`, `module-graph`, and `module-info` facts emitted by the
native compiler.

`neboc check ENTRY --unit A --unit B --deny-effectful-init` accepts a pure graph
without output. An imported runtime `start` is rejected with
`NEBO-RF166-G153-001`; imports cannot satisfy the missing authority. A module
initialization cycle is rejected with `NEBO-RF166-G153-002`, before Assembly or
ELF publication.

Bounded runtime initialization uses caller-owned `ModuleInitState`. Preflight
checks cycles, rejected nodes, and explicit capability grants before mutation.
Success publishes every node READY together. Injected failure rolls earlier
runtime nodes back in reverse-topological order, leaves zero READY nodes, and
makes retry fail closed. `executeOnce`, `rollback`, and `cleanup` are idempotent;
each runtime execution and cleanup counter can advance at most once.

The eight examples under `examples/rf204/G153/` are real three-unit Nebo
programs. Each produces a distinct native exit value, and reversed unit order
produces byte-identical reports, Assembly, and ELF files.
