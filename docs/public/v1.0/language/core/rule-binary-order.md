# binary order

Evaluate ordinary operands left to right exactly once, including owned Bytes operands.

```text
Identity: N1-binary-order (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-binary-order — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Evaluate ordinary operands left to right exactly once, including owned Bytes operands.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### semantics:eval-binary-17-2b; expected 23

```nebo
(Int.x)observe(){x.console();x.return;}start(){(17.observe()+29.observe()).console();23.return;}
```

Oracle: {"console_text_utf8": "172946", "independent_builds": 2, "kinds": \[4, 4, 4\], "process_exit": 23, "runtime_sha256": "395aa21e7363ef22c33c92f52f79107b28c03c2934966210d0a1042f6ee451e1"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
