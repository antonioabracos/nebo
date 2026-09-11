# Semantic navigation and rename

Nebo exposes revision-bound navigation through both the `neboc` CLI and the
stdio LSP server. Hover, signature help, definition, references and rename all
resolve the same canonical `SymbolId`; a matching spelling is not sufficient.

## CLI

```text
neboc hover <file>:<line>:<column> [--workspace <directory>]
neboc signature-help <file>:<line>:<column> [--workspace <directory>]
neboc definition <file>:<line>:<column>|<name-or-SymbolId> [--workspace <directory>]
neboc references <name-or-SymbolId> [--workspace <directory>]
neboc rename <name-or-SymbolId> <new-name> --preview [--workspace <directory>]
neboc rename <name-or-SymbolId> <new-name> --apply --allow-breaking [--workspace <directory>]
neboc navigation-corpus --verify
```

Every JSON report contains its source snapshot digest and G160 project-index
revision. Pass `--revision <sha256>` when a caller must reject results from a
changed workspace. Queries are bounded, local-only and never access a network.

## Definitions and references

Source definitions use the canonical `DocRecord` name span. Receiver-first
methods reuse G161 receiver `TypeId` and overload ownership. Builtins and
compiled NI-v1 interfaces produce explicit synthetic URIs; interface-only
symbols are read-only. Reference results are ordered by path, byte offset and
role, and exclude comments, strings and unrelated homonyms.

## Rename safety

Rename is preview-only unless `--apply` is supplied. Public identity changes
are classified `BREAKING` and additionally require `--allow-breaking`. The
plan preserves local import aliases and edits only the declaration and imports
bound to the selected `SymbolId`.

Before publication, the new sources pass compiler/DocRecord admission. Apply
uses the existing G048 `FixPlan` transaction; a stale source, collision,
verification failure or write failure publishes no partial edit. The resulting
workspace is reindexed and must expose the new identity.

LSP `textDocument/rename` returns the same preview as a `WorkspaceEdit` with a
confirmation annotation for breaking changes. The editor remains responsible
for applying that preview.

## Stable diagnostics

`NEBO-RF166-G162-001` through `NEBO-RF166-G162-010` cover invalid input,
unresolved or ambiguous identity, stale snapshot, collision, authorization,
read-only identities, resource budgets, verification/transaction failure and
internal protocol errors. A failure emits no JSON navigation state.
