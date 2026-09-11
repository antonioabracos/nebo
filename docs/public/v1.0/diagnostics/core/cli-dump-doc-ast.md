# neboc dump doc-ast

Inspect the native documentation AST.

```text
Identity: cli:dump doc-ast (CLI_FORM)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
neboc dump doc-ast app.no
```

## Behavior and usage

Doc blocks attach to actual declarations and source spans. This inspection alone does not verify an embedded example.

## Exit codes and remediation

Exit 0 means this command completed its stated operation; source errors use 1, invalid usage or environment uses 2, and an internal failure uses 101. An emitted file is not runtime proof. Correct the diagnostic and retry; never execute a rejected or partially published artifact.

## Example commands

neboc dump doc-ast app.no

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### interface:docrecord-17; expected 17

```nebo
doc { title: "Runtime documentation"; summary: "A material value"; effects { pure; } capabilities { none; } example "exit-17" {start(){17.return;}} law "law-exit-29" {start(){29.return;}} }
// Public imports resolve the original declaration and value.
module app;
import "project.core".values;
start values.token;

```

Oracle: {"independent_builds": 2, "process_exit": 17, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

Provider core.no

```nebo
module core;
export public token = 17;

```

Provider util.no

```nebo
module util;
export public delta = 7;

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
