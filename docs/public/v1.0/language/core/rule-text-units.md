# text units

UTF-8 byte length, Unicode scalar count and grapheme segmentation are distinct operations. Each operation must obey its declared unit and boundary behavior; no implicit normalization is performed.

```text
Identity: N1-text-units (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-text-units — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

UTF-8 byte length, Unicode scalar count and grapheme segmentation are distinct operations. Each operation must obey its declared unit and boundary behavior; no implicit normalization is performed.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### text:trim-2; expected 23

```nebo
start(){"".trim().console();23.return;}
```

Oracle: {"console_text_utf8": "", "independent_builds": 2, "kinds": \[\], "process_exit": 23, "publications": 1, "runtime_sha256": "bb7902ccefdecac2dc18792c91b9097229164142e3a6b5a9ab7832a78f745e3d"}

## Rejected examples

### text:arity-trim; expected NEBO-TEXT-TRANSFORM-ARITY

```nebo
start(){"Nebo".trim(1);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-TEXT-TRANSFORM-ARITY"}

## Additional observations and limits

```text
[
  {
    "case_id": "text:native-g054_adversarial_test",
    "category": "native-control",
    "elf_sha256": "b2ce8979439d6b94e542f4c634c0109a55c8ad13653b538e5f2c7f51be7b42b1"
  },
  {
    "case_id": "text:native-g055_adversarial_test",
    "category": "native-control",
    "elf_sha256": "5598991281df87c5f61c63b904980a4f6b7c9b85eafd99852418b16da934be25"
  },
  {
    "case_id": "text:native-g057_adversarial_test",
    "category": "native-control",
    "elf_sha256": "4679293e36505f4a153c444f4f143cfd8ec56ef45c7bc92282913902fb39fa5d"
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

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
