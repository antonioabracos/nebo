# overload ranking

Exact supported receiver/argument types select deterministically regardless of declaration order. Named/default calls retain their bounded pure profile.

```text
Identity: N1-overload-ranking (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-overload-ranking — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Exact supported receiver/argument types select deterministically regardless of declaration order. Named/default calls retain their bounded pure profile.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### control:named-weighted-3-17; expected 133

```nebo
(Int.self)weighted(Int.a,Int.b=7){(self+a+a+a+b+b+b+b+b+b+b).return;}start(){5.weighted(b:17,a:3).return;}
```

Oracle: {"independent_builds": 2, "process_exit": 133, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### control:call-argument; expected NEBO_CALL_UNDEFINED

```nebo
(Int.self)add(Int.delta){(self+delta).return;}start(){17.add(true).return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_CALL_UNDEFINED"}

## Related entries

[Index](index.md)

- [rule-call-order](rule-call-order.md)

- [rule-inference-and-binding](rule-inference-and-binding.md)

- [rule-import-no-grant](rule-import-no-grant.md)

- [rule-match](rule-match.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/control_test.py — SHA-256 f957fe13774970b7f71e2678f8b0cc721b8cb8b15891c02552f9129ff2e2e0be

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
