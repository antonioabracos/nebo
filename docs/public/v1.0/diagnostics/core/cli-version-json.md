# neboc --version-json

Read the canonical product version, compiler identity, language Edition and supported target as JSON.

```text
Identity: cli:--version-json (CLI_FORM)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
neboc --version-json
```

## Identity contract

This read-only command emits the canonical NEBO-VERSION-v1 record. The product version and language Edition are separate fields. It neither reads source nor creates an artifact.

## Additional observations and limits

```text
[
  {
    "case_id": "version-consistency:native-human-machine",
    "category": "CLI",
    "exit": 0,
    "observed_json": {
      "cli": "neboc 1.1.0",
      "compiler": "neboc",
      "edition": "1.0",
      "language": "Nebo",
      "schema": "NEBO-VERSION-v1",
      "target": "x86_64-systemv-elf-linux",
      "version": "1.1.0"
    }
  }
]
```

## Related entries

[Index](index.md)

- [cli-version](cli-version.md)

## Provenance

- version/NEBO-VERSION.json — SHA-256 af4258c4488498878cd320455ef90b516d63e28d12b9ada1ebe949b10584159c
