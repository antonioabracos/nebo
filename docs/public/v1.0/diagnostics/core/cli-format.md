# neboc format

Format source while preserving protected payloads.

```text
Identity: cli:format (CLI_FORM)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
neboc format source.no --check|--diff|--stdout|--write
```

## Behavior and usage

Use --check, --diff or --stdout to inspect without mutation. Raw/multiline strings and comments retain their payload bytes. --write atomically replaces only the explicitly selected source; the conformance test confines it to disposable source fixtures.

## Exit codes and remediation

Exit 0 indicates a completed operation or already canonical --check. Exit 1 from --check means formatting differs. Invalid source, invalid ranges and usage errors return 2 without changing the source. Inspect --diff before --write; do not interpret --check exit 1 as a compiler type error.

## Example commands

neboc format examples/rf204/G185/RF204-G185-S07.no --stdout

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Additional observations and limits

```text
[
  {
    "case_id": "formatter:raw-preserve",
    "formatted_sha256": "c49ae1de58acd7d1a2babd369d620af0f315b6a454c8328265fbebc9a977c546"
  },
  {
    "case_id": "formatter:multiline-preserve",
    "formatted_sha256": "43a0bbd8e2c010d0994b3a9432cfd45009ae0b06fdc3d701421b4d02365e9ef8"
  }
]
```

## Related entries

[Index](index.md)

- [NEBO_CLI_USAGE](NEBO_CLI_USAGE.md)

- [NEBO_SOURCE_BOM_FORBIDDEN](NEBO_SOURCE_BOM_FORBIDDEN.md)

- [NEBO_SOURCE_TOO_LARGE](NEBO_SOURCE_TOO_LARGE.md)

- [NEBO_LEX_INVALID_UTF8](NEBO_LEX_INVALID_UTF8.md)

## Provenance

- compiler/driver/cli/linux-x86_64/cli_driver.asm — SHA-256 0005784201af6835cb78990bd7f0800aa5b745fb813a6bd744934254766560ed

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
