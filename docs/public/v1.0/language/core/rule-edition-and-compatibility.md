# edition and compatibility

Edition 1 specifies the admitted bounded profile. The current selector also accepts Edition 2 for compatible forms; unknown IDs reject. Neither selector nor migration preview activates a reserved form or changes files.

```text
Identity: N1-edition-and-compatibility (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-edition-and-compatibility — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Edition 1 specifies the admitted bounded profile. The current selector also accepts Edition 2 for compatible forms; unknown IDs reject. Neither selector nor migration preview activates a reserved form or changes files.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### local:S07; expected 67

```nebo
// The CLI reports typed failures separately from a valid process result.
start(){(256+67).console();67.return;}

```

Oracle: {"console_text_utf8": "323", "independent_builds": 2, "kinds": \[4\], "process_exit": 67, "runtime_sha256": "c1d884ae1acae293df163061932b94b5988b45fa886f0ae9bd5f1d331313ecff"}

## Additional observations and limits

```text
[
  {
    "case_id": "edition:edition-1"
  },
  {
    "case_id": "edition:edition-2"
  },
  {
    "case_id": "edition:edition-rejected-3"
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
