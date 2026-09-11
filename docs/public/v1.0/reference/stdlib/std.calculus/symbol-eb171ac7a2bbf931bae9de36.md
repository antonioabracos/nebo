# std.calculus — std.calculus

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

```text
Identity: module:std.calculus (MODULE_IDENTITY)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: INTRINSIC_NAMESPACE_NOT_AN_IMPORTABLE_MODULE
```

## Syntax or signature

```text
Intrinsic namespace: std.calculus. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace.
```

## Stability and availability

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

## Canonical import policy

Intrinsic namespace: std.calculus. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace. Importing never grants capabilities. std.core and std.console exports retain their canonical core/prelude reference owners.

## Packages and compiled interfaces

The stdlib registry supplies visibility metadata. G180 package manifests and lockfiles describe content-addressed offline packages; an intrinsic namespace is not a fictitious shipped package. See docs/reference/packages/PACKAGE-MANIFEST-SPEC.md and LOCKFILE-SPEC.md. Serialized .ni declarations retain their original SymbolIds; intrinsic entries do not acquire fabricated IDs.

## Executed examples

### boundedoperator:dom-049-e288ab-0; expected 2

```nebo
start(){∫(x,0,2,trapezoid,1,16,[0,1,2]).value();}
```

Oracle: {"capabilities": {"console": "NO_DOCUMENT_OBSERVER", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "filesystem_effects": {}, "independent_builds": 2, "process_exit": 2, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### boundedoperator:dom-055-negative; expected NEBO_TYPE_UNSUPPORTED_OPERATOR

```nebo
start(){divergence(3,invalidUnit,numeric,central,64,[2,3,4]).value();}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_UNSUPPORTED_OPERATOR"}

## Related entries

[Index](index.md)

- [symbol-a0f0c8e43beb532c974c8bbb](symbol-a0f0c8e43beb532c974c8bbb.md)

- [symbol-57d9b36a2f42c74436b04265](symbol-57d9b36a2f42c74436b04265.md)

- [symbol-500eaa399db7165cb2120fdf](symbol-500eaa399db7165cb2120fdf.md)

- [symbol-7acf68cdae99cd50c126f130](symbol-7acf68cdae99cd50c126f130.md)

- [symbol-c7b9b9dd2560b3603daa32c0](symbol-c7b9b9dd2560b3603daa32c0.md)

- [symbol-eeca64d3406b6fae70ff9824](symbol-eeca64d3406b6fae70ff9824.md)

- [symbol-5d55df0a3fb03d6f2746948a](symbol-5d55df0a3fb03d6f2746948a.md)

- [symbol-97f080720c6783e1b4891216](symbol-97f080720c6783e1b4891216.md)

## Provenance

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/bounded_operator_test.py — SHA-256 a756e75fb059c5f5837b1ab76490c31b8e92762f0400cad0d2545ff0532beaf5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
