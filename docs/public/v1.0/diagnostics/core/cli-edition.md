# neboc --edition

Select the admitted language Edition.

```text
Identity: cli:--edition (CLI_FORM)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
neboc check source.no --edition 1|2
```

## Behavior and usage

Edition 1 is the frozen documentation profile. Edition 2 accepts the currently compatible forms. Unknown IDs reject; no selector activates reserved grammar.

## Exit codes and remediation

Exit 0 means this command completed its stated operation; source errors use 1, invalid usage or environment uses 2, and an internal failure uses 101. An emitted file is not runtime proof. Correct the diagnostic and retry; never execute a rejected or partially published artifact.

## Example commands

neboc check examples/rf204/G185/RF204-G185-S07.no --edition 1

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Additional observations and limits

```text
[
  {
    "case_id": "edition:edition-1"
  },
  {
    "case_id": "edition:edition-2"
  },
  {
    "case_id": "edition:edition-rejected-3"
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
