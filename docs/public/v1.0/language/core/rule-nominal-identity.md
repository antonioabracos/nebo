# nominal identity

Alias layout equals referent layout; newtype requires explicit construction/unwrap; enum discriminants and active payloads remain distinct.

```text
Identity: N1-nominal-identity (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-nominal-identity — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Alias layout equals referent layout; newtype requires explicit construction/unwrap; enum discriminants and active payloads remain distinct.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### semantics:alias-identity-Int; expected 8

```nebo
type alias Count = Int;start(){Count.sizeOf().return;}
```

Oracle: {"independent_builds": 2, "process_exit": 8, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### composite:newtype-wrong-value; expected NEBO_TYPE_MISMATCH

```nebo
newtype UserId(Int);start(){UserId(17).unwrap();UserId(true).unwrap().return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [rule-builtin-types](rule-builtin-types.md)

- [rule-no-coercions](rule-no-coercions.md)

- [rule-generic-constraints](rule-generic-constraints.md)

- [rule-explicit-conversions](rule-explicit-conversions.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/composite_test.py — SHA-256 55ac93ae5384e68a22489d0b68dbd8acc1cb83ed7fdb2b3b2a1b5c71de6f01f3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
