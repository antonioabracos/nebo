# format and render

Format/interpolation arguments retain lexical evaluation and typed domain checks. Admitted FormatPlan/RenderPlan profiles preserve exact text and node effects; interpolation expressions must be pure.

```text
Identity: N1-format-and-render (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-format-and-render — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Format/interpolation arguments retain lexical evaluation and typed domain checks. Admitted FormatPlan/RenderPlan profiles preserve exact text and node effects; interpolation expressions must be pure.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### interpolation:silent; expected 23

```nebo
start(){"${17+29}";23.return;}
```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### interpolation:missing-name; expected NEBO-FORMAT-003

```nebo
start(){"${absent}";23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-FORMAT-003"}

## Additional observations and limits

```text
[
  {
    "case_id": "format:native-format_plan_native",
    "category": "native-owner",
    "exit": 0
  },
  {
    "case_id": "format:native-g059_runtime_test",
    "category": "native-owner",
    "exit": 0
  },
  {
    "case_id": "format:native-g060_runtime_test",
    "category": "native-owner",
    "exit": 0
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

- tests/rf204/G170/interpolation_test.py — SHA-256 54716aea543d4dd9d1b212acd63e1819d4e6b54b6bef5a597f0b50fab2d9a68a

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
