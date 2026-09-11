# Nebo language guide

This guide describes the verified local compiler profile `neboc 1.1.0`.
Programs define `start`; a terminal expression can be evaluated without making
it a process exit status.
Bindings are introduced by writing an expression followed by `.name`, and
arithmetic has the usual precedence. The current certified target is
`x86_64-systemv-elf-linux`.

<!-- expect-exit: 0 -->
```nebo
start() {
    7 + 5 * 3;
}
```

Validate with `neboc check`, inspect deterministic output with `neboc emit-asm`,
and produce a native static ELF with `neboc build`. The specification candidate
and conformance manifest define the normative bounded subset; native Assembly
ABIs elsewhere in the repository do not by themselves make source syntax
public.

## Edition 1.0 public indexing compatibility

`NSR-RES-015-COMPAT-1.0.1` preserves public 1.0.1 reads from a bound immutable
`Array<Int,4>` with a single literal index from 0 to 3. General indexing and
slicing remain RESERVED. Prefer `values.at(index)` in new source; existing
`values[index]` needs no migration, warning suppression or compatibility flag.
Both spellings use the same Array owner and checked bounds policy.
No user-defined index protocol or automatic quick fix is enabled.
