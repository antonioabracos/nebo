# effect lattice

Effect tracking is a compiler contract, not a public constructor or a promise that its internal bit layout is a language type. Public effectful calls remain subject to declared purity and authority.

```text
Identity: N1-effect-lattice (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Syntax or signature

```text
N1-effect-lattice — NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Scope and constraints

Effect tracking is a compiler contract, not a public constructor or a promise that its internal bit layout is a language type. Public effectful calls remain subject to declared purity and authority.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Additional observations and limits

```text
[
  {
    "binary_sha256": "51df24dae62e15033d1fb785d2adf10a31c114d7e0292d7bbe156e6e76404622",
    "case_id": "semantic-native:effect-inference",
    "proof_kind": "native assertions over real owner state; not public source admission"
  },
  {
    "case_id": "semantic-native:effect-lattice",
    "cases": 2895,
    "input_sha256": "66089b57445cd2e714e2256d12c01a2a6bdbeb8ab6fe6495277f40704d76225d",
    "observed_sha256": "0610638cddbc971c941b9b862ff9eb9b9fc9951d6d70563492cc0813a3ac2077",
    "oracle": "independent Boolean lattice and bytewise FNV"
  }
]
```

## Related entries

[Index](index.md)

- [rule-move](rule-move.md)

- [rule-copy-clone](rule-copy-clone.md)

- [rule-borrow-aliasing](rule-borrow-aliasing.md)

- [rule-lifetime-escape](rule-lifetime-escape.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
