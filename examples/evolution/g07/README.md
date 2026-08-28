# G07 bounded scalar generics example

`../g07-scalar-generics.no` is the stable executable candidate example for the
G07 slice. It demonstrates exact Int receiver inference through the canonical
receiver-first generic identity declaration and exits natively with value 7.

The example is validated through `neboc check`, deterministic `emit-asm`,
`build`, static ELF inspection and native execution. Aggregate generics,
multiple parameters, explicit type arguments, coercions, code sharing and
runtime dictionaries remain unavailable.
