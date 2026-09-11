# builtin.Random — builtin.Random

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

```text
Identity: module:builtin.Random (MODULE_IDENTITY)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: INTRINSIC_NAMESPACE_NOT_AN_IMPORTABLE_MODULE
```

## Syntax or signature

```text
Intrinsic namespace: builtin.Random. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace.
```

## Stability and availability

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

## Canonical import policy

Intrinsic namespace: builtin.Random. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace. Importing never grants capabilities. std.core and std.console exports retain their canonical core/prelude reference owners.

## Packages and compiled interfaces

The stdlib registry supplies visibility metadata. G180 package manifests and lockfiles describe content-addressed offline packages; an intrinsic namespace is not a fictitious shipped package. See docs/reference/packages/PACKAGE-MANIFEST-SPEC.md and LOCKFILE-SPEC.md. Serialized .ni declarations retain their original SymbolIds; intrinsic entries do not acquire fabricated IDs.

## Executed examples

### random:bernoulli-0-0.0; expected 23

```nebo
start(){Random.seed(0).r;r.bernoulli(0.0).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "false", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[5\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "940d3adc4d04ace895143d0978dec24529bd7cd0402dc4546664f9bb6d6f0e22", "text": {"bytes_hex": "66616c7365"}}

## Rejected examples

### random:seed-arity; expected NEBO_TYPE_MISMATCH

```nebo
start(){Random.seed().r;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Additional observations and limits

```text
[
  {
    "case_id": "random:native-distribution-controls",
    "category": "native"
  }
]
```

## Related entries

[Index](index.md)

- [symbol-6f8edce072d8a856a31deee5](symbol-6f8edce072d8a856a31deee5.md)

- [symbol-ece7bc8a1e5c9f72845a0d88](symbol-ece7bc8a1e5c9f72845a0d88.md)

- [symbol-d5f1c90194a9dc923b306063](symbol-d5f1c90194a9dc923b306063.md)

- [symbol-d0be8b7a7db3a24dcafc0886](symbol-d0be8b7a7db3a24dcafc0886.md)

- [symbol-9c7602f695d64398d22e8609](symbol-9c7602f695d64398d22e8609.md)

- [symbol-65fa9e940b44ce607f6669b4](symbol-65fa9e940b44ce607f6669b4.md)

- [symbol-6f9e7800d1752681a405ea0d](symbol-6f9e7800d1752681a405ea0d.md)

- [symbol-01dbaf023fbcf45cc6e77545](symbol-01dbaf023fbcf45cc6e77545.md)

## Provenance

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/random_test.py — SHA-256 a4d3692d30d6947812089d0ad64318a32a6a9279c567ac96481f207daeb95516
