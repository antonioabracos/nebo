# declared target and limits

Executable conformance here is x86_64 Linux System V ELF. Other targets and wider profiles acquire no guarantee by name. Public bounds and failure policies are enumerated in IMPLEMENTATION-DEFINED-REGISTRY.tsv; compiler and test-harness budgets are distinguished.

```text
Identity: N1-declared-target-and-limits (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-declared-target-and-limits — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Executable conformance here is x86_64 Linux System V ELF. Other targets and wider profiles acquire no guarantee by name. Public bounds and failure policies are enumerated in IMPLEMENTATION-DEFINED-REGISTRY.tsv; compiler and test-harness budgets are distinguished.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### source:S07; expected 29

```nebo
// Linux exposes the low byte of this source-level integer result.
// The mathematical temporary has a separate value and cannot become the exit.
start(){(-19 * -1).console();(256+29).return;}

```

Oracle: {"console_text_utf8": "19", "independent_builds": 2, "kinds": \[4\], "process_exit": 29, "runtime_sha256": "c8d97171c9edd7bdd006fcf600caaa47cff785c8a451be584930f2b8849715b6"}

## Additional observations and limits

```text
[
  {
    "case_id": "interface:target-mismatch",
    "category": "negative",
    "observed_sha256": "ed82a495571c18146879f22aca8fc2d3d663ece5be749d496cb8a81537387910",
    "published": false,
    "reason": 3
  },
  {
    "case_id": "lexical-native:mf019/recovery_test:17",
    "observation_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  },
  {
    "case_id": "lexical-native:mf019/recovery_test:18",
    "observation_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  }
]
```

## Related entries

[Index](index.md)

- [rule-allocation-budget](rule-allocation-budget.md)

- [rule-arithmetic-failures](rule-arithmetic-failures.md)

- [rule-output-capacity](rule-output-capacity.md)

- [rule-recursion-budget](rule-recursion-budget.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
