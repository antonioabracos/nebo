# source effect inference

Interpolation permits only pure expressions, including transitive callees; discarded effects still execute outside pure contexts.

```text
Identity: N1-source-effect-inference (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-source-effect-inference — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Interpolation permits only pure expressions, including transitive callees; discarded effects still execute outside pure contexts.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### semantics:pure-interpolation-17; expected 23

```nebo
(Int.x)pure(){(x+7).return;}start(){"${17.pure()}".console();23.return;}
```

Oracle: {"console_text_utf8": "24", "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "runtime_sha256": "5bf0e20c37dc19cd3f10f1780c745659fc6dde66dab6d5127f747f82a97a2348"}

## Rejected examples

### interpolation:effect-mutable; expected NEBO_INTERPOLATION_EFFECT_FORBIDDEN

```nebo
(Int.x)plus(){x.value.mutable;value+=1;value.return;}start(){"${17.plus()}";23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_INTERPOLATION_EFFECT_FORBIDDEN"}

## Related entries

[Index](index.md)

- [rule-move](rule-move.md)

- [rule-copy-clone](rule-copy-clone.md)

- [rule-borrow-aliasing](rule-borrow-aliasing.md)

- [rule-lifetime-escape](rule-lifetime-escape.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/interpolation_test.py — SHA-256 54716aea543d4dd9d1b212acd63e1819d4e6b54b6bef5a597f0b50fab2d9a68a

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
