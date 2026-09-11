# neboc --no-prelude

Disable implicit std.prelude visibility.

```text
Identity: cli:--no-prelude (CLI_FORM)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
neboc check|build|emit-asm source.no --no-prelude
```

## Behavior and usage

Explicit imports restore the required symbols. Disabled prelude injection grants no names or capabilities; the Standard Library is not globally loaded.

## Exit codes and remediation

Exit 0 means this command completed its stated operation; source errors use 1, invalid usage or environment uses 2, and an internal failure uses 101. An emitted file is not runtime proof. Correct the diagnostic and retry; never execute a rejected or partially published artifact.

## Example commands

neboc check examples/rf204/G185/RF204-G185-S06.no --no-prelude

## Executed examples

### local:explicit-Option; expected 31

```nebo
import "std.core" { Option; }.core;
import "std.console" { console; scan; }.output;
start(){Option<Int>(Some(31)).x;x.unwrapOr(7).return;}
```

Oracle: {"independent_builds": 2, "no_prelude": true, "process_exit": 31, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### local:hidden-Option; expected NEBO-RF166-G163-002

```nebo
start(){Option<Int>(Some(31)).x;x.unwrapOr(7).return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-RF166-G163-002", "no_prelude": true}

## Related entries

[Index](index.md)

- [NEBO_CLI_USAGE](NEBO_CLI_USAGE.md)

- [NEBO_SOURCE_BOM_FORBIDDEN](NEBO_SOURCE_BOM_FORBIDDEN.md)

- [NEBO_SOURCE_TOO_LARGE](NEBO_SOURCE_TOO_LARGE.md)

- [NEBO_LEX_INVALID_UTF8](NEBO_LEX_INVALID_UTF8.md)

## Provenance

- compiler/driver/cli/linux-x86_64/cli_driver.asm — SHA-256 0005784201af6835cb78990bd7f0800aa5b745fb813a6bd744934254766560ed

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
