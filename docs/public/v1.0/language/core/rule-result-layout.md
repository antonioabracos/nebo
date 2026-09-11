# result layout

Ok/Err preserve distinct success/error types and owned payloads across function returns.

```text
Identity: N1-result-layout (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-result-layout — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Ok/Err preserve distinct success/error types and owned payloads across function returns.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### optionresult:two-results; expected 23

```nebo
start(){Result<Int,Int>(Ok(17)).a;Result<Int,Int>(Err(71)).b;a.get().console();b.getErr().console();a.get().console();23.return;}
```

Oracle: {"console_text_utf8": "177117", "independent_builds": 2, "kinds": \[4, 4, 4\], "process_exit": 23, "runtime_sha256": "04d3694f576fe2c4a5f8741f3852a0f6eeee3bb845527764dbef496463392a89"}

## Related entries

[Index](index.md)

- [rule-move](rule-move.md)

- [rule-copy-clone](rule-copy-clone.md)

- [rule-borrow-aliasing](rule-borrow-aliasing.md)

- [rule-lifetime-escape](rule-lifetime-escape.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/option_result_test.py — SHA-256 b91cfdcf0a149083e241308f7ced2c95532758131a3b0d9d15297e026cff81fc

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
