# precedence associativity

The registered binding powers and associativity govern grouping: power is right associative and binds more strongly than unary minus; parentheses explicitly override grouping.

```text
Identity: N1-precedence-associativity (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-precedence-associativity — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

The registered binding powers and associativity govern grouping: power is right associative and binds more strongly than unary minus; parentheses explicitly override grouping.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### source:power-right; expected 23

```nebo
start(){(2^3^2).console();23.return;}
```

Oracle: {"console_text_utf8": "512", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "a65ea5ab907f9dd854ad645885cb866b4c4a8be423b3784fa555bb084de8b9ec"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0/00-PRECEDENCE-REGISTRY.tsv — SHA-256 8c21768f0b351f1fb2b9effe196c940e274f85bfce33ba5566563d4083e19a43

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
