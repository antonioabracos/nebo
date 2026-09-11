# Migration guide

Preserve the original source, package lock and expected outputs before a
migration. Validate the unchanged project first, apply only mechanical edition
steps, then repeat check, deterministic assembly generation, native build and
tests. Review every breaking-change report; unsafe transformations are denied.

For RC2 compatibility, retain edition range 1 through 2 and ABI/runtime version
0 unless a package declares narrower bounds. Do not infer source-level support
from a native Assembly ABI. A migration is complete only when package restore,
target compatibility and the project's own expected outputs are unchanged.

```bash
build/bin/neboc check program.no
build/bin/neboc emit-asm program.no -o program.asm
build/bin/neboc build program.no -o program
```

## Edition 1.0 public indexing compatibility

`NSR-RES-015-COMPAT-1.0.1` preserves public 1.0.1 reads from a bound immutable
`Array<Int,4>` with a single literal index from 0 to 3. General indexing and
slicing remain RESERVED. Prefer `values.at(index)` in new source; existing
`values[index]` needs no migration, warning suppression or compatibility flag.
Both spellings use the same Array owner and checked bounds policy.
No user-defined index protocol or automatic quick fix is enabled.
