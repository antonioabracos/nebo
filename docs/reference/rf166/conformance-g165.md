# RF166 G165 bounded conformance commands

G165 composes the existing module, compiled-interface, semantic-documentation,
semantic-index, LSP, prelude-migration, and comment-trivia owners. It does not
introduce another parser, resolver, module graph, `.ni` reader, documentation
engine, or semantic index.

The local, offline commands are:

```text
neboc conformance modules-docs-lsp
neboc fuzz-source --domains imports,docs,comments --seed 165 --budget 4
neboc migration-check rf166 <paths>
```

`conformance` runs the five integrated suites twice in independent scratch
roots and compares their canonical reports. `fuzz-source` uses replayable seeds
and bounded budgets; its report distinguishes crashes, hangs, and corruption.
`migration-check` is always preview-only and verifies that every input byte is
unchanged. None of these commands performs network access or uploads a corpus.

The checked-in RF166 manifest contains all 146 fronts. Rows for G166 are marked
`NEXT_CLOSEOUT_NOT_STARTED`; inclusion is coverage planning, not execution of
the next group.
