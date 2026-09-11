# comments

Line comments continue to line end. Block comments nest to depth 64 inclusive; depth 65 rejects without an artifact. Comments cannot activate executable statements. A doc block is structured syntax, not trivia.

```text
Identity: N1-comments (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-comments — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Line comments continue to line end. Block comments nest to depth 64 inclusive; depth 65 rejects without an artifact. Comments cannot activate executable statements. A doc block is structured syntax, not trivia.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### source:S01; expected 22

```nebo
// Comments and raw Unicode text preserve their exact payload bytes.
start(){/* outer /* inner */ comment */0x1d.value;"Ω雪".byteLength().console();r"two  spaces".byteLength().console();(value − 7).return;}

```

Oracle: {"console_text_utf8": "511", "independent_builds": 2, "kinds": \[4, 4\], "process_exit": 22, "runtime_sha256": "e7280983006af53de23e93c5147696b797b5a1cab84e56ed5b388a77e96db0bb"}

## Rejected examples

### lexical:nested-comment-65; expected NEBO_LEX_BLOCK_COMMENT_DEPTH

```nebo
start(){/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*x*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_LEX_BLOCK_COMMENT_DEPTH"}

## Additional observations and limits

```text
[
  {
    "case_id": "lexical:trivia"
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
