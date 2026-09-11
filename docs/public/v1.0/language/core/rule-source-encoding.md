# source encoding

Source must be valid UTF-8. Invalid sequences, executable bidi controls and confusable spellings reject; byte offsets are measured in the original bytes. Formatting must preserve literal and comment payloads.

```text
Identity: N1-source-encoding (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-source-encoding — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Source must be valid UTF-8. Invalid sequences, executable bidi controls and confusable spellings reject; byte offsets are measured in the original bytes. Formatting must preserve literal and comment payloads.

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

### lexical:unicode-0; expected NEBO_SOURCE_BIDI_CONTROL

```nebo
start(){(17‪7).return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_SOURCE_BIDI_CONTROL"}

## Additional observations and limits

```text
[
  {
    "case_id": "formatter:multiline-preserve",
    "formatted_sha256": "43a0bbd8e2c010d0994b3a9432cfd45009ae0b06fdc3d701421b4d02365e9ef8"
  },
  {
    "case_id": "formatter:raw-preserve",
    "formatted_sha256": "c49ae1de58acd7d1a2babd369d620af0f315b6a454c8328265fbebc9a977c546"
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
