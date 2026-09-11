# copy clone

Value copies and explicit owned clones remain independent; clone allocation is accounted and released.

```text
Identity: N1-copy-clone (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-copy-clone — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Value copies and explicit owned clones remain independent; clone allocation is accounted and released.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### ownership:clone-arena; expected 23

```nebo
start(){Arena.withCapacity(128).a;a.clone().b;b.allocate<Int>(3).c;a.allocate<Int>(7).d;23.return;}
```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "c84acf5970db35198ddaa25a3664ee3643809ee36f2106b3b8fb52db3d703b0b"}

## Related entries

[Index](index.md)

- [rule-move](rule-move.md)

- [rule-borrow-aliasing](rule-borrow-aliasing.md)

- [rule-lifetime-escape](rule-lifetime-escape.md)

- [rule-cleanup](rule-cleanup.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/ownership_test.py — SHA-256 ed4f10840cdff23e8f7f520c0603208b18e27f2b31c346846bd9e805a2516e4d

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
