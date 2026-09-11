# match

Current enum matching observes only the selected active variant and rejects invalid patterns according to the finite source profile.

```text
Identity: N1-match (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-match — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Current enum matching observes only the selected active variant and rejects invalid patterns according to the finite source profile.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### semantics:match-None-0; expected 29

```nebo
start(){Option<Int>(None()).value;match(value){Some(payload) -> payload.return;None() -> 29.return;}}
```

Oracle: {"independent_builds": 2, "process_exit": 29, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### semantics:match-negative-non-exhaustive; expected NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-008

```nebo
start() {
    Result<Int,Bool>(Ok(42)).value;
    match(value) {
        Ok(payload) -> payload.return;
    }
}

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-008"}

## Related entries

[Index](index.md)

- [rule-call-order](rule-call-order.md)

- [rule-inference-and-binding](rule-inference-and-binding.md)

- [rule-overload-ranking](rule-overload-ranking.md)

- [rule-import-no-grant](rule-import-no-grant.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
