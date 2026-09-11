# std.math — std.math

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

```text
Identity: module:std.math (MODULE_IDENTITY)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: INTRINSIC_NAMESPACE_NOT_AN_IMPORTABLE_MODULE
```

## Syntax or signature

```text
Intrinsic namespace: std.math. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace.
```

## Stability and availability

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

## Canonical import policy

Intrinsic namespace: std.math. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace. Importing never grants capabilities. std.core and std.console exports retain their canonical core/prelude reference owners.

## Packages and compiled interfaces

The stdlib registry supplies visibility metadata. G180 package manifests and lockfiles describe content-addressed offline packages; an intrinsic namespace is not a fictitious shipped package. See docs/reference/packages/PACKAGE-MANIFEST-SPEC.md and LOCKFILE-SPEC.md. Serialized .ni declarations retain their original SymbolIds; intrinsic entries do not acquire fabricated IDs.

## Executed examples

### math:implicit-float; expected 0

```nebo
start(){std.math.sqrt(9.0);}

```

Oracle: {"binary64_tolerance": {"absolute": 1e-12, "relative": 1e-12}, "capabilities": {"console": "NO_DOCUMENT_OBSERVER", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "filesystem_effects": {}, "independent_builds": 2, "independent_math_values": \[\[5, 2, 3.0\]\], "math_trace_sha256": "aaa60e286908e90dfa6a68050d4bb7b4d367bd66f7d4fae34fdf723ddca891f1", "observed_math_calls": 1, "process_exit": 0, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### operator:wrong-unary-e2889a; expected NEBO_TYPE_MISMATCH

```nebo
(Int.self)invalid(){(√true).return;}start(){17.invalid().console();23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-08c8301bf69c6f35087e43d6](symbol-08c8301bf69c6f35087e43d6.md)

- [symbol-fdc13381d00d100fe02deb4d](symbol-fdc13381d00d100fe02deb4d.md)

- [symbol-0aaf1c4f534d4c65ba8fd527](symbol-0aaf1c4f534d4c65ba8fd527.md)

- [symbol-bbc3cfe8aa8c7ad445cd5efb](symbol-bbc3cfe8aa8c7ad445cd5efb.md)

- [symbol-1ab0c6490e7b6e2ba4c8284a](symbol-1ab0c6490e7b6e2ba4c8284a.md)

- [symbol-81e7897fc284f0f65896c8c4](symbol-81e7897fc284f0f65896c8c4.md)

- [symbol-33127c562f762ad4fa435362](symbol-33127c562f762ad4fa435362.md)

- [symbol-bf252df6a37e3beb55785d24](symbol-bf252df6a37e3beb55785d24.md)

## Provenance

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/math_oracle.py — SHA-256 a8b0d3e88a49a701df02b467c2a7e31fd5f235ea821907eb3701ae50e17524d4

- tests/rf204/G170/math_return_test.py — SHA-256 80e2b9b0eb7f676a90c810e50ac8451ed7fe7145012a7e085715f85997e26b81

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
