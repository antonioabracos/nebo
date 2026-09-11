# Offline diagnostics

The catalog exactly reproduces the current compatibility registry, including native IDs, stable codes, span and format contracts. General explanations are the six version-1 NEBO-E/W/N/H/ICE records accepted by `neboc explain`; canonical native codes are looked up in catalog.json. No alias between these namespaces is implied.

`neboc diagnostic-schema --version 1` describes JSON-lines required fields. `neboc check source.no --message-format json-lines --color never` emits machine diagnostics. `neboc check source.no --show-fixes --color never` emits a human preview without modifying source; --show-fixes is incompatible with machine formats. Primary start/end are half-open UTF-8 byte offsets. SARIF byteOffset/byteLength and LSP UTF-16 or UTF-8 ranges describe the same source span. `--show-fixes` only previews classified edits; apply through the transactional fix/refactor commands after reviewing the source snapshot.

Exit codes are command-specific. The compiler's current published table is share/nebo/cli/exit-codes.txt; formatter --check returns 1 for a difference, and tool usage failures return 2.
