# doc attachment

A doc block attaches to a material declaration through native AST/DocRecord identity. Its examples and laws are actual Nebo programs. Textual registry identities and serialized SymbolIds must not be conflated.

```text
Identity: N1-doc-attachment (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-doc-attachment — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

A doc block attaches to a material declaration through native AST/DocRecord identity. Its examples and laws are actual Nebo programs. Textual registry identities and serialized SymbolIds must not be conflated.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

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

- [rule-call-order](rule-call-order.md)

- [rule-inference-and-binding](rule-inference-and-binding.md)

- [rule-overload-ranking](rule-overload-ranking.md)

- [rule-import-no-grant](rule-import-no-grant.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
