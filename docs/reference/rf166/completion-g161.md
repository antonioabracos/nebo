# Receiver completion and auto-import

Nebo completion is a local, revision-bound projection over the canonical
compiler semantic owners. It never executes the receiver and never opens a
network connection. The public diagnostic commands are:

```text
neboc completion-debug <file>:<line>:<column>
neboc completion-corpus --verify
```

`completion-debug` reports the source revision, cursor, receiver `TypeId`,
eligible candidates, origin and deterministic rank components. Line and column
are one-based. `--workspace`, `--limit`, `--deadline-ms`, context-effect,
context-capability and context-constraint options make query bounds explicit.

The language server advertises `textDocument/completion` with `.` as a trigger.
Initial items deliberately contain only display, order, insertion and opaque
revision-bound identity data. `completionItem/resolve` adds the canonical
signature and documentation. A document change invalidates earlier items.

Auto-import is never implicit. A local public candidate carries an explicit
plan; `--apply-auto-import <itemId>` validates the same source revision and then
delegates the atomic source edit to the canonical import owner. Unknown, stale,
private, unavailable or ambiguous candidates change no bytes.

Ranking uses only origin locality, prefix exactness, stability, local use,
canonical name and `SymbolId`. Remote telemetry is neither read nor emitted.
