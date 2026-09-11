# arithmetic failures

Checked integer overflow/division traps do not wrap silently; explicit status preserves canonical return semantics.

```text
Identity: N1-arithmetic-failures (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-arithmetic-failures — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Checked integer overflow/division traps do not wrap silently; explicit status preserves canonical return semantics.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### math:non-math-return; expected 23

```nebo
start(){(11+12).return;}

```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### math:text-return; expected NEBO_TYPE_MISMATCH

```nebo
start(){"bad".return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [rule-allocation-budget](rule-allocation-budget.md)

- [rule-output-capacity](rule-output-capacity.md)

- [rule-recursion-budget](rule-recursion-budget.md)

- [rule-publication-atomicity](rule-publication-atomicity.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/math_return_test.py — SHA-256 80e2b9b0eb7f676a90c810e50ac8451ed7fe7145012a7e085715f85997e26b81

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
