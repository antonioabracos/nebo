# discard and return

Discard keeps effects; return suppresses subsequent control paths and runs required cleanup.

```text
Identity: N1-discard-and-return (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-discard-and-return — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Discard keeps effects; return suppresses subsequent control paths and runs required cleanup.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### ownership:early-return; expected 23

```nebo
start(){Allocator.system().a;a.allocate(31).b;23.return;a.allocate(79).c;}
```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "3f6a9947e79fe6793c8eb195ded323bd5ffbedfa5448b5c9bb8612f7c1b2a33e"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/ownership_test.py — SHA-256 ed4f10840cdff23e8f7f520c0603208b18e27f2b31c346846bd9e805a2516e4d

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
