# maximal munch

The longest registered token in its admitted context is consumed; compound Unicode tokens retain their whole UTF-8 spans. Recognition alone does not activate a reserved grammar form.

```text
Identity: N1-maximal-munch (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-maximal-munch — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

The longest registered token in its admitted context is consumed; compound Unicode tokens retain their whole UTF-8 spans. Recognition alone does not activate a reserved grammar form.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### local:S02; expected 41

```nebo
// Power is right associative; Boolean short-circuit preserves effects.
(Bool.x)mark(){x.console();x.return;}
start(){(2^3^2).console();(-2^2).console();(false.mark() ∧ true.mark()).console();41.return;}

```

Oracle: {"console_text_utf8": "512-4falsefalse", "independent_builds": 2, "kinds": \[4, 4, 5, 5\], "process_exit": 41, "runtime_sha256": "9ab941b0db1b78a42a7ab7ddcb8a72dcf4cb4b402891d75e70d36700a627aa21"}

## Additional observations and limits

```text
[
  {
    "case_id": "edition:reserved-remains-closed-across-editions"
  },
  {
    "case_id": "lexical:maximal-3f3f3d",
    "kind": 104
  },
  {
    "case_id": "lexical:maximal-e281bbc2b9",
    "kind": 157
  }
]
```

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
