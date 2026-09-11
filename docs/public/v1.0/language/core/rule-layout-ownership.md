# layout ownership

Distinct live owned values must remain independent and valid through their permitted lifetimes. Internal descriptor offsets and generation representation are not language syntax.

```text
Identity: N1-layout-ownership (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-layout-ownership — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Distinct live owned values must remain independent and valid through their permitted lifetimes. Internal descriptor offsets and generation representation are not language syntax.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### ownership:reset-and-reuse; expected 23

```nebo
start(){Arena.withCapacity(32).a;a.allocate<Int>(3).x;a.reset().r;a.allocate<Int>(4).y;23.return;}
```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "3aa9867ca7e3b337944928085838a18e06cf6e7394c6bafc80badc8364ca784f"}

## Related entries

[Index](index.md)

- [rule-move](rule-move.md)

- [rule-copy-clone](rule-copy-clone.md)

- [rule-borrow-aliasing](rule-borrow-aliasing.md)

- [rule-lifetime-escape](rule-lifetime-escape.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/ownership_test.py — SHA-256 ed4f10840cdff23e8f7f520c0603208b18e27f2b31c346846bd9e805a2516e4d

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
