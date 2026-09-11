# Void

No-payload result identity; no Void(...) constructor is admitted.

```text
Identity: type:Void (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: NATIVE_DEFINITION_ONLY
```

## Syntax or signature

```text
Void
Native TypeId: 1 (not SymbolId)
```

## Logical layout

Zero logical payload; no storage ownership.

## Construction and members

Effect-only statement result; use explicit Int return at the program entry.

## Protocols and ownership

No payload is owned or borrowed. This identity does not grant a public constructor, Copy implementation or callable drop member.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Additional observations and limits

```text
[
  {
    "case_id": "compatibility-native:datalayout",
    "category": "target",
    "fields": [
      0,
      8,
      8,
      8,
      8,
      1,
      1,
      1,
      16,
      8,
      8,
      8,
      8,
      8,
      16,
      1,
      127,
      1,
      819825426,
      0
    ],
    "mutated_fields": 20,
    "observed_sha256": "55227e2060e563b7900c358bd6beedcaddb0064280b3be036a443ab29098afcd"
  },
  {
    "base": 0,
    "case_id": "types:type-1",
    "category": "native-type",
    "flags": 1,
    "kind": 1,
    "observed_sha256": "698bdc7f7bcf2e25a572179df9363572e0119450db2dcd6c67a54cf5eef03be4",
    "type_id": 1
  }
]
```

## Related entries

[Index](index.md)

- [type-Bool](type-Bool.md)

- [type-Int](type-Int.md)

- [type-Text](type-Text.md)

- [type-Console](type-Console.md)

## Provenance

- compiler/semantic/types/type_table.inc — SHA-256 a104864da8c77b21c4186ba1cdcf8d40800c464a8edbcccf31fc1ed57b4cf528

- compiler/semantic/types/type_table.asm — SHA-256 1c04c832d2df1cd5900cf37fa73aa91884c79d7754d1e85c8ce29fa473e227b3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
