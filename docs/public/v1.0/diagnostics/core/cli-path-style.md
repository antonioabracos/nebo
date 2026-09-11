# neboc --path-style

Control --path-style for diagnostics.

```text
Identity: cli:--path-style (CLI_FORM)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
neboc check source.no --path-style relative|workspace|absolute
```

## Behavior and usage

Select human diagnostic path style. Machine schema identity and byte spans remain unchanged.

## Exit codes and remediation

Exit 0 means this command completed its stated operation; source errors use 1, invalid usage or environment uses 2, and an internal failure uses 101. An emitted file is not runtime proof. Correct the diagnostic and retry; never execute a rejected or partially published artifact. These options belong to check, except the explicitly shared format/color options.

## Example commands

neboc check invalid.no --path-style relative

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Rejected examples

### cli:path-absolute; expected NEBO_NAME_UNDEFINED

```nebo
start(){Int.x;absent.x;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_NAME_UNDEFINED"}

## Additional observations and limits

```text
[
  {
    "case_id": "cli:usage-14",
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
