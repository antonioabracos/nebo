# no coercions

No implicit Bool/Int/Float/Char/Text conversion at binding boundaries; rejected initializer retains causal type error.

```text
Identity: N1-no-coercions (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-no-coercions — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

No implicit Bool/Int/Float/Char/Text conversion at binding boundaries; rejected initializer retains causal type error.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### local:S03; expected 43

```nebo
// Distinct typed values retain their logical units and binding types.
start(){Int.count;47.count;Text.label;"Ω雪".label;Bytes.fromValues(7,19,31,43).data;count.console();label.byteLength().console();data.at(2).console();43.return;}

```

Oracle: {"console_text_utf8": "47531", "independent_builds": 2, "kinds": \[4, 4, 4\], "process_exit": 43, "runtime_sha256": "06932dd097d38a02db3a9cc53844aabcd188d03e983cec94c90d94d71fe09415"}

## Rejected examples

### semantics:no-coercion-Bool; expected NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH

```nebo
start(){Bool.x;17.x;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH"}

## Related entries

[Index](index.md)

- [rule-builtin-types](rule-builtin-types.md)

- [rule-nominal-identity](rule-nominal-identity.md)

- [rule-generic-constraints](rule-generic-constraints.md)

- [rule-explicit-conversions](rule-explicit-conversions.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
