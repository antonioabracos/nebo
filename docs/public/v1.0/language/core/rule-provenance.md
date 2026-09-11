# provenance

Provenance metadata must preserve authenticated source/transform relationships when that tooling contract is used. Metadata lineage does not add a source-language provenance constructor.

```text
Identity: N1-provenance (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Syntax or signature

```text
N1-provenance — NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Scope and constraints

Provenance metadata must preserve authenticated source/transform relationships when that tooling contract is used. Metadata lineage does not add a source-language provenance constructor.

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
    "binary_sha256": "4d97fccb8c7a075deac2afd16510766b807b1e0a321799e594fdcbbdaea903ad",
    "case_id": "semantic-native:provenance",
    "proof_kind": "native assertions over real owner state; not public source admission"
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
