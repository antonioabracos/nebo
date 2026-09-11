# neboc --show-fixes

Control --show-fixes for diagnostics.

```text
Identity: cli:--show-fixes (CLI_FORM)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
neboc check source.no --show-fixes
```

## Behavior and usage

Display fix information only with human/short check diagnostics. JSON-lines/SARIF and output-building modes reject this option.

## Exit codes and remediation

Exit 0 means this command completed its stated operation; source errors use 1, invalid usage or environment uses 2, and an internal failure uses 101. An emitted file is not runtime proof. Correct the diagnostic and retry; never execute a rejected or partially published artifact. These options belong to check, except the explicitly shared format/color options.

## Example commands

neboc check invalid.no --show-fixes

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Additional observations and limits

```text
[
  {
    "case_id": "cli:fixes-human",
    "category": "diagnostics",
    "exit": 1,
    "observed_sha256": "636a6ff718bfe7e7a4e695d6819b2b8256397414903306698db2d75245b5e50f"
  },
  {
    "case_id": "cli:fixes-short",
    "category": "diagnostics",
    "exit": 1,
    "observed_sha256": "636a6ff718bfe7e7a4e695d6819b2b8256397414903306698db2d75245b5e50f"
  },
  {
    "case_id": "cli:usage-12",
    "category": "negative",
    "exit": 2,
    "observed_sha256": "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"
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
