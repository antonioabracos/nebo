# short circuit

&amp;&amp; and its exact alias ∧, and || and its exact alias ∨, evaluate the right operand only when required. The English words and/or/not are not executable aliases in Edition 1.

```text
Identity: N1-short-circuit (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-short-circuit — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

&amp;&amp; and its exact alias ∧, and || and its exact alias ∨, evaluate the right operand only when required. The English words and/or/not are not executable aliases in Edition 1.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### operator:short-or; expected 23

```nebo
start(){(true || (1/0==0)).console();23.return;}
```

Oracle: {"console_text_utf8": "true", "independent_builds": 2, "kinds": \[5\], "process_exit": 23, "runtime_sha256": "26e99610443e30ab87a629aa5de2392ce6d0117574455307c7c97e44b2fcac90"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
