# std.net — std.net

{"availability": "TARGET_GATED", "capabilities": \["network"\], "editions": \["1"\], "effects": \["network"\], "exports": \["Socket", "TcpStream"\], "importGrantsCapabilities": false, "layer": "STDLIB", "name": "std.net", "since": "Edition 1", "stability": "stable", "targets": \["x86_64-systemv-elf-linux"\]}

```text
Identity: module:std.net (MODULE_IDENTITY)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: TARGET_GATED
```

## Syntax or signature

```text
import "std.net" { Socket; TcpStream; }.library;
```

## Stability and availability

{"availability": "TARGET_GATED", "capabilities": \["network"\], "editions": \["1"\], "effects": \["network"\], "exports": \["Socket", "TcpStream"\], "importGrantsCapabilities": false, "layer": "STDLIB", "name": "std.net", "since": "Edition 1", "stability": "stable", "targets": \["x86_64-systemv-elf-linux"\]}

## Canonical import policy

import "std.net" { Socket; TcpStream; }.library; Importing never grants capabilities. std.core and std.console exports retain their canonical core/prelude reference owners.

## Packages and compiled interfaces

The stdlib registry supplies visibility metadata. G180 package manifests and lockfiles describe content-addressed offline packages; an intrinsic namespace is not a fictitious shipped package. See docs/reference/packages/PACKAGE-MANIFEST-SPEC.md and LOCKFILE-SPEC.md. Serialized .ni declarations retain their original SymbolIds; intrinsic entries do not acquire fabricated IDs.

## Execution boundary

This is a target/environment boundary or module identity. It grants no runtime capability. No live device, network session or stable runtime implementation is inferred from metadata.

## Negative applicability

No additional source diagnostic is invented for this row. The stated receiver and profile bounds and the associated owner tests define admissibility.

## Additional observations and limits

```text
[
  {
    "case_id": "local:unsupported-target",
    "category": "target",
    "unsupported": "aarch64-linux"
  },
  {
    "case_id": "local:module-std.net",
    "category": "SDK",
    "record": {
      "availability": "TARGET_GATED",
      "capabilities": [
        "network"
      ],
      "edition": "1",
      "editions": [
        "1"
      ],
      "effects": [
        "network"
      ],
      "exports": [
        "Socket",
        "TcpStream"
      ],
      "importGrantsCapabilities": false,
      "layer": "STDLIB",
      "name": "std.net",
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

- [symbol-7cb2a6b9b3bf5772b65b975f](symbol-7cb2a6b9b3bf5772b65b975f.md)

- [symbol-88a55a68219eaed552e864cf](symbol-88a55a68219eaed552e864cf.md)

## Provenance

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
