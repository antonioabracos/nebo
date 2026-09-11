# RF166 G149 internal foundation ABI

This is an internal x86-64 SysV Assembly ABI. It does not create a public Nebo
API or CLI. Every input is borrowed for the duration of the call and every
output is caller-owned. Inputs and outputs must be non-null, eight-byte aligned,
and non-aliasing where the implementation publishes a report. A failed call
leaves the output byte-for-byte unchanged.

| Owner | Input | Output | Success condition |
|---|---|---:|---|
| `neboc_rf166_language_authority_audit_new` | 12 authority rows | 56 bytes | exact IDs, states, and future owners |
| `neboc_rf166_import_syntax_registry_freeze` | 8 decision rows | 56 bytes | six assumed, one reserved, one rejected |
| `neboc_rf166_doc_schema_registry_freeze` | 2 decision rows | 56 bytes | singular assumed, plural rejected |
| `neboc_rf166_interface_format_registry_freeze` | 1 decision row | 56 bytes | `.ni` assumed with G154 owner |
| `neboc_rf166_prelude_contract_freeze` | 3 decision rows | 56 bytes | one material and two assumed |
| `neboc_rf166_example_manifest_freeze` | 8 source identities | 32 bytes | all identities non-zero and distinct |
| `neboc_rf166_planning_freeze` | 146 nodes, 145 edges, four counts | 72 bytes | exact linear DAG and pack partition |
| `neboc_rf166_foundation_closeout` | request plus seven reports | 136 bytes | authenticated reports, zero findings, next G150 not started |

Rows are three little-endian qwords: identity, state, and owner. State values are
1 `MATERIAL`, 2 `ASSUMED`, 3 `RESERVED`, and 4 `REJECTED`. Reports begin with
schema 1 and contain bounded counters followed by a deterministic 64-bit digest.
The closeout authenticates every schema and counter before computing its digest;
it never trusts a total count alone.

Status zero means success. Invalid pointers or aliases return
`NEBOC_STATUS_INVALID_ARGUMENT`. Wrong counts, identities, state transitions,
owners, duplicates, DAG edges, pack sizes, report schemas, open findings, or
activation flags return `NEBOC_STATUS_INVALID_SOURCE`.
