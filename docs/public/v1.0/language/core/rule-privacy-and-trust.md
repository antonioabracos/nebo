# privacy and trust

Sensitive input must follow the admitted redaction and flow policy; it must not appear in a redacted sink. Native Sensitive/Trusted metadata does not declare additional public source constructors.

```text
Identity: N1-privacy-and-trust (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Syntax or signature

```text
N1-privacy-and-trust — NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Scope and constraints

Sensitive input must follow the admitted redaction and flow policy; it must not appear in a redacted sink. Native Sensitive/Trusted metadata does not declare additional public source constructors.

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
    "binary_sha256": "ed161d5908de131005cfda4d032db174dd438e38ab134d557e1565d7e528c548",
    "case_id": "semantic-native:privacy",
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
