# std.core — std.core

{"availability": "BOUNDED_PUBLIC", "capabilities": \[\], "editions": \["1"\], "effects": \[\], "exports": \["Eq", "Error", "IntoIterator", "Iterator", "Option", "Ord", "Ordering", "Range", "Result"\], "importGrantsCapabilities": false, "layer": "STDLIB", "name": "std.core", "since": "Edition 1", "stability": "stable", "targets": \["x86_64-systemv-elf-linux"\]}

```text
Identity: module:std.core (MODULE_IDENTITY)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: BOUNDED_PUBLIC
```

## Syntax or signature

```text
import "std.core" { Eq; Error; IntoIterator; Iterator; Option; Ord; Ordering; Range; Result; }.library;
```

## Stability and availability

{"availability": "BOUNDED_PUBLIC", "capabilities": \[\], "editions": \["1"\], "effects": \[\], "exports": \["Eq", "Error", "IntoIterator", "Iterator", "Option", "Ord", "Ordering", "Range", "Result"\], "importGrantsCapabilities": false, "layer": "STDLIB", "name": "std.core", "since": "Edition 1", "stability": "stable", "targets": \["x86_64-systemv-elf-linux"\]}

## Canonical import policy

import "std.core" { Eq; Error; IntoIterator; Iterator; Option; Ord; Ordering; Range; Result; }.library; Importing never grants capabilities. std.core and std.console exports retain their canonical core/prelude reference owners.

## Packages and compiled interfaces

The stdlib registry supplies visibility metadata. G180 package manifests and lockfiles describe content-addressed offline packages; an intrinsic namespace is not a fictitious shipped package. See docs/reference/packages/PACKAGE-MANIFEST-SPEC.md and LOCKFILE-SPEC.md. Serialized .ni declarations retain their original SymbolIds; intrinsic entries do not acquire fabricated IDs.

## Negative applicability

No additional source diagnostic is invented for this row. The stated receiver and profile bounds and the associated owner tests define admissibility.

## Executed examples

### local:S01; expected 31

```nebo
// Explicit stdlib imports preserve visibility without the default prelude.
import "std.core" { Option; }.core;
import "std.console" { console; }.output;
start(){Option<Int>(Some(37)).a;Option<Int>(None()).b;a.unwrapOr(11).console();b.unwrapOr(19).console();31.return;}

```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "3719", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4, 4\], "no_prelude": true, "process_exit": 31, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "b3a0da47f18ada3d4e99c8f0f4e44a97b95bf66e03f07d8032609f32a953750b", "text": {"bytes_hex": "33373139"}}

## Additional observations and limits

```text
[
  {
    "case_id": "local:module-std.core",
    "category": "SDK",
    "record": {
      "availability": "BOUNDED_PUBLIC",
      "capabilities": [],
      "edition": "1",
      "editions": [
        "1"
      ],
      "effects": [],
      "exports": [
        "Eq",
        "Error",
        "IntoIterator",
        "Iterator",
        "Option",
        "Ord",
        "Ordering",
        "Range",
        "Result"
      ],
      "importGrantsCapabilities": false,
      "layer": "STDLIB",
      "name": "std.core",
      "since": "Edition 1",
      "stability": "stable",
      "target": "x86_64-systemv-elf-linux",
      "targets": [
        "x86_64-systemv-elf-linux"
      ]
    }
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
