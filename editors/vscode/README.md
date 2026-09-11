# Nebo Local Tooling for VS Code

This source-only adapter connects a trusted local workspace to the in-tree
`neboc`, canonical formatter and bounded stdio LSP. It registers check, build,
emit-assembly and format commands for local `.no` files. Commands use argument
arrays with `shell: false`; the adapter contains no downloader, registry,
marketplace, socket, telemetry, update or remote-execution code.

The default paths are workspace-relative (`build/bin/neboc`,
`tools/rf27-lsp.py`). Override them only with trusted local paths. Output is
limited to 1 MiB and lines that look secret-bearing are replaced with
`[REDACTED]` before the VS Code output or error sink.

RF27-G24-F06 is certified by a deterministic mocked-host protocol suite because
the VS Code host is optional in this environment. No `.vsix` package is built
or published, and no new Nebo source syntax is activated.
