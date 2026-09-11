# literal payload

Radix/separator integer spellings preserve their values. Float is binary64, Char is one Unicode scalar, Text retains decoded UTF-8 bytes; raw and multiline forms preserve their respective escape and newline rules.

```text
Identity: N1-literal-payload (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-literal-payload — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Radix/separator integer spellings preserve their values. Float is binary64, Char is one Unicode scalar, Text retains decoded UTF-8 bytes; raw and multiline forms preserve their respective escape and newline rules.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### literal:literal-ratio-0.75; expected 23

```nebo
start(){(0.75==(3.0/4.0)).console();23.return;}
```

Oracle: {"console_text_utf8": "true", "independent_builds": 2, "kinds": \[5\], "process_exit": 23, "runtime_sha256": "26e99610443e30ab87a629aa5de2392ce6d0117574455307c7c97e44b2fcac90"}

## Rejected examples

### literal:mixed-ratio; expected NEBO_TYPE_MISMATCH

```nebo
start(){(0.75==(3/4)).console();23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

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
  },
  {
    "case_id": "literal:bits-0-rounding-0",
    "category": "native-literal-bits",
    "expected_bits": "0x0",
    "observed_bits": "0x0",
    "rounding_mode": 0
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

- tests/rf204/G170/float_literal_test.py — SHA-256 83f63f66f2dd0bebafa9bb2ca682c93c38b1c231205db2c253ac5b51f361f2a1

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
