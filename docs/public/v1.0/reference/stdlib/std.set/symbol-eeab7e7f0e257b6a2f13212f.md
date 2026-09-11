# std.set — std.set

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

```text
Identity: module:std.set (MODULE_IDENTITY)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: INTRINSIC_NAMESPACE_NOT_AN_IMPORTABLE_MODULE
```

## Syntax or signature

```text
Intrinsic namespace: std.set. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace.
```

## Stability and availability

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

## Canonical import policy

Intrinsic namespace: std.set. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace. Importing never grants capabilities. std.core and std.console exports retain their canonical core/prelude reference owners.

## Packages and compiled interfaces

The stdlib registry supplies visibility metadata. G180 package manifests and lockfiles describe content-addressed offline packages; an intrinsic namespace is not a fictitious shipped package. See docs/reference/packages/PACKAGE-MANIFEST-SPEC.md and LOCKFILE-SPEC.md. Serialized .ni declarations retain their original SymbolIds; intrinsic entries do not acquire fabricated IDs.

## Executed examples

### operator:membership-e28888-4-2; expected 23

```nebo
start(){Array<Int,0> [].left;Array<Int,0> [].right;(2 ∈ left).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "false", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[5\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "940d3adc4d04ace895143d0978dec24529bd7cd0402dc4546664f9bb6d6f0e22", "text": {"bytes_hex": "66616c7365"}}

## Rejected examples

### operator:wrong-set-c397; expected NEBO_TYPE_MISMATCH

```nebo
(Int.self)invalid(){(17 × 29).return;}start(){7.invalid().console();23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-6d6b6ab9478a23e5e503c042](symbol-6d6b6ab9478a23e5e503c042.md)

- [symbol-b42706e891f5607a73cb573a](symbol-b42706e891f5607a73cb573a.md)

- [symbol-441cd9343bb9792f2a30dd2b](symbol-441cd9343bb9792f2a30dd2b.md)

- [symbol-1d25c638f7eae27b1acc7904](symbol-1d25c638f7eae27b1acc7904.md)

- [symbol-e6aac400d0188a0f5f6fd90d](symbol-e6aac400d0188a0f5f6fd90d.md)

- [symbol-2dfeb1de31c2d139532b37c1](symbol-2dfeb1de31c2d139532b37c1.md)

- [symbol-ade8cd491b826f12ea982227](symbol-ade8cd491b826f12ea982227.md)

- [symbol-34a695d76228ebdf57e87da4](symbol-34a695d76228ebdf57e87da4.md)

## Provenance

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
