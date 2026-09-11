# generic constraints

Supported scalar generic constraints are checked, not erased; const arguments specialize independently.

```text
Identity: N1-generic-constraints (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-generic-constraints — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Supported scalar generic constraints are checked, not erased; const arguments specialize independently.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### composite:const-generic-two-values-17-29; expected 46

```nebo
const generic<N> (Int.value)extent(){N.return;}start(){0.extent<17>().left;0.extent<29>().right;(left+right).return;}
```

Oracle: {"independent_builds": 2, "process_exit": 46, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### composite:generic-ord-bool; expected NEBO_TYPE_MISMATCH

```nebo
generic<T> (T.value)hold() where T: Ord {value.return;}start(){true.hold().return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [rule-builtin-types](rule-builtin-types.md)

- [rule-no-coercions](rule-no-coercions.md)

- [rule-nominal-identity](rule-nominal-identity.md)

- [rule-explicit-conversions](rule-explicit-conversions.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/composite_test.py — SHA-256 55ac93ae5384e68a22489d0b68dbd8acc1cb83ed7fdb2b3b2a1b5c71de6f01f3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
