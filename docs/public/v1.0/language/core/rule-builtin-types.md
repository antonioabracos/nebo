# builtin types

Bool, Int64, binary64 Float, Unicode Char, UTF-8 Text and Bytes retain distinct typed identities.

```text
Identity: N1-builtin-types (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-builtin-types — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Bool, Int64, binary64 Float, Unicode Char, UTF-8 Text and Bytes retain distinct typed identities.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### binding:Int-0-typed; expected 23

```nebo
start(){Int.value;37.value;value.console();23.return;}
```

Oracle: {"console_text_utf8": "37", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "b5bcc903c755e76bcd44796e0c9a73bc00a30900436647160f53337f2ca1df09"}

## Related entries

[Index](index.md)

- [rule-no-coercions](rule-no-coercions.md)

- [rule-nominal-identity](rule-nominal-identity.md)

- [rule-generic-constraints](rule-generic-constraints.md)

- [rule-explicit-conversions](rule-explicit-conversions.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/binding_test.py — SHA-256 e030e23aab8fa49674e14b4cf50af041571cb97954f7fbb0873f0bed3b3eab39

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
