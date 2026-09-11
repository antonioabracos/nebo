# aggregate order

List arguments and named product fields evaluate in lexical source order, independent of storage field order.

```text
Identity: N1-aggregate-order (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-aggregate-order — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

List arguments and named product fields evaluate in lexical source order, independent of storage field order.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### semantics:eval-collection-17; expected 23

```nebo
(Int.x)observe(){x.console();x.return;}start(){List<Int>.from([17.observe(),29.observe()]).v;v.at(0).console();v.at(1).console();23.return;}
```

Oracle: {"console_text_utf8": "17291729", "independent_builds": 2, "kinds": \[4, 4, 4, 4\], "process_exit": 23, "runtime_sha256": "cf430168a48fd29bd918cdef2d4c90e485bc981ddb7a7bcabb7d8a4a5a358f18"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
