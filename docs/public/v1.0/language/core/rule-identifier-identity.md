# identifier identity

Identifiers use ASCII letters/underscore and subsequent ASCII digits as admitted by the lexical token owner; exact spelling is significant. No Unicode normalization or confusable substitution is implicit; keyword boundaries remain distinct.

```text
Identity: N1-identifier-identity (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-identifier-identity — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Identifiers use ASCII letters/underscore and subsequent ASCII digits as admitted by the lexical token owner; exact spelling is significant. No Unicode normalization or confusable substitution is implicit; keyword boundaries remain distinct.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### local:S01; expected 37

```nebo
// Nested comments are trivia; raw Unicode payloads keep their bytes.
start(){/* one /* two */ end */0x2b.value;r"Ω  雪".byteLength().console();(value − 6).return;}

```

Oracle: {"console_text_utf8": "7", "independent_builds": 2, "kinds": \[4\], "process_exit": 37, "runtime_sha256": "b790d78c12a0f9e3b23c453aeadb16b57b80bac298e2bf35b05bad67e7380b99"}

## Rejected examples

### lexical:unavailable-4; expected NEBO_LEX_INVALID_CHARACTER

```nebo
start(){Int.café;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_LEX_INVALID_CHARACTER"}

## Additional observations and limits

```text
[
  {
    "case_id": "lexical:kw_start",
    "kind": 10
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
