# Compatibility guide

The canonical compiler identifies as `1.1.0`. The bounded
compatibility model recognizes legacy language edition 1 and current edition 2,
with ABI version 0 and runtime version 0. `neboc compatibility-report` exposes
the current contract, `neboc check <source> --edition 1|2` admits a source under
an explicit edition, and `neboc migrate --from 1 --to 2` emits a read-only,
mechanical migration plan. Unsafe or reverse migrations fail closed.

The only certified target is `x86_64-systemv-elf-linux`. An AArch64 assembler
was observed locally, but the Nebo backend, complete linker path, emulator and
target conformance were unavailable, so AArch64 remains deferred and
uncertified. Packages must satisfy their declared edition and ABI ranges.
Breaking or unsafe migrations are reported rather than silently rewritten.

## Edition 1.0 public indexing compatibility

`NSR-RES-015-COMPAT-1.0.1` preserves public 1.0.1 reads from a bound immutable
`Array<Int,4>` with a single literal index from 0 to 3. General indexing and
slicing remain RESERVED. Prefer `values.at(index)` in new source; existing
`values[index]` needs no migration, warning suppression or compatibility flag.
Both spellings use the same Array owner and checked bounds policy.
No user-defined index protocol or automatic quick fix is enabled.
