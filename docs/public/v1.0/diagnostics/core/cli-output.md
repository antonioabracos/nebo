# neboc -o

Choose the explicit output artifact path.

```text
Identity: cli:-o (CLI_FORM)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
neboc emit-asm|build source.no -o output
```

## Behavior and usage

Applicable output modes require a destination. Invalid source or unsupported diagnostic-only options must not publish a new artifact.

## Exit codes and remediation

Exit 0 means this command completed its stated operation; source errors use 1, invalid usage or environment uses 2, and an internal failure uses 101. An emitted file is not runtime proof. Correct the diagnostic and retry; never execute a rejected or partially published artifact.

## Example commands

neboc build examples/rf204/G185/RF204-G185-S07.no -o build/nebo-example

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### local:S07; expected 67

```nebo
// The CLI reports typed failures separately from a valid process result.
start(){(256+67).console();67.return;}

```

Oracle: {"console_text_utf8": "323", "independent_builds": 2, "kinds": \[4\], "process_exit": 67, "runtime_sha256": "c1d884ae1acae293df163061932b94b5988b45fa886f0ae9bd5f1d331313ecff"}

## Additional observations and limits

```text
[
  {
    "case_id": "cli:build-option-0",
    "category": "negative",
    "exit": 2,
    "observed_sha256": "80df32ecedd07d3781243cfc2da8c7c4971d459a9f40572cd8cde258fbd5877f"
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
