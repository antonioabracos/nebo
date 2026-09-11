# std.net — Socket

Network access explicitly forbidden in this mission; no socket or external service is opened

```text
Identity: claim:7be836b65074404a981f6ec3 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: TARGET_GATED
```

## Syntax or signature

```text
Socket — TARGET_OR_ENVIRONMENT_JUSTIFIED
```

## Target and environment caveat

Network access explicitly forbidden in this mission; no socket or external service is opened

## No implicit authority

Imports establish visibility only. No network connection or live frontend execution is claimed. The target remains x86_64-systemv-elf-linux.

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

- [symbol-ba54195ac02f43dfcccc6b51](symbol-ba54195ac02f43dfcccc6b51.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-PROFILE-BOUNDARIES.tsv — SHA-256 f75432d694f4cdd8f47bc28f34f8d031ba92fdf5147cd157161356c9832036e3

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
