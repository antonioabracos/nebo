# call order

Evaluate receiver then positional arguments once; native hidden-result storage preserves effects and caller ownership.

```text
Identity: N1-call-order (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-call-order — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Evaluate receiver then positional arguments once; native hidden-result storage preserves effects and caller ownership.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### semantics:eval-call-17; expected 23

```nebo
(Int.x)observe(){x.console();x.return;}(Int.x)sum(Int.y,Int.z){(x+y+z).return;}start(){17.observe().sum(29.observe(),71.observe()).console();23.return;}
```

Oracle: {"console_text_utf8": "172971117", "independent_builds": 2, "kinds": \[4, 4, 4, 4\], "process_exit": 23, "runtime_sha256": "b06f327553d8bbb44190c39f386472fc06dde2838bd4570ba4c66ecda98b3631"}

## Related entries

[Index](index.md)

- [rule-inference-and-binding](rule-inference-and-binding.md)

- [rule-overload-ranking](rule-overload-ranking.md)

- [rule-import-no-grant](rule-import-no-grant.md)

- [rule-match](rule-match.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
