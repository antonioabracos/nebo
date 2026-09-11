# recursion budget

At most 64 active supported call frames; depth-boundary programs terminate with a defined trap, never hang.

```text
Identity: N1-recursion-budget (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-recursion-budget — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

At most 64 active supported call frames; depth-boundary programs terminate with a defined trap, never hang.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### control:recursion-63; expected 7

```nebo
(Int.self)countdown(){if(self<=0){7.return;}else{(self-1).countdown().return;}}start(){63.countdown().return;}
```

Oracle: {"independent_builds": 2, "process_exit": 7, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Related entries

[Index](index.md)

- [rule-allocation-budget](rule-allocation-budget.md)

- [rule-arithmetic-failures](rule-arithmetic-failures.md)

- [rule-output-capacity](rule-output-capacity.md)

- [rule-publication-atomicity](rule-publication-atomicity.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/control_test.py — SHA-256 f957fe13774970b7f71e2678f8b0cc721b8cb8b15891c02552f9129ff2e2e0be

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
