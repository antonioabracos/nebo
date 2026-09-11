# std.text.format — std.text.format

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

```text
Identity: module:std.text.format (MODULE_IDENTITY)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: INTRINSIC_NAMESPACE_NOT_AN_IMPORTABLE_MODULE
```

## Syntax or signature

```text
Intrinsic namespace: std.text.format. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace.
```

## Stability and availability

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

## Canonical import policy

Intrinsic namespace: std.text.format. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace. Importing never grants capabilities. std.core and std.console exports retain their canonical core/prelude reference owners.

## Packages and compiled interfaces

The stdlib registry supplies visibility metadata. G180 package manifests and lockfiles describe content-addressed offline packages; an intrinsic namespace is not a fictitious shipped package. See docs/reference/packages/PACKAGE-MANIFEST-SPEC.md and LOCKFILE-SPEC.md. Serialized .ni declarations retain their original SymbolIds; intrinsic entries do not acquire fabricated IDs.

## Executed examples

### format:literal-percent; expected 23

```nebo
start(){"100%%".format().console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "100%", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "publications": 1, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "05fcf98a3e7d26c7a9ec87775ee67142e010f30e302930f6ff70e9759154c092", "text": {"bytes_hex": "31303025"}}

## Rejected examples

### format:unknown; expected NEBO-FORMAT-001

```nebo
start(){"%z".format(17);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-FORMAT-001"}

## Additional observations and limits

```text
[
  {
    "case_id": "interpolation:tooling-format-invalid",
    "category": "tooling"
  }
]
```

## Related entries

[Index](index.md)

- [symbol-c973eecc55bc2512680f3162](symbol-c973eecc55bc2512680f3162.md)

- [symbol-6ac2d489f76ce86c2f2ee354](symbol-6ac2d489f76ce86c2f2ee354.md)

## Provenance

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/format_test.py — SHA-256 f4539de327f15036d30b3184af38af88a729bce118650704c350d30f04820318

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
