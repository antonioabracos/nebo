# BasisPoints

A distinct basis-points fixed-point ratio quantity.

```text
Identity: type:BasisPoints (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
BasisPoints
Native TypeId: 17 (not SymbolId)
```

## Logical layout

Shares the ratio representation without erasing its type.

## Construction and members

Use the exact basis-points operator profile; arbitrary unit coercion is not admitted.

## Protocols and ownership

The BasisPoints value preserves its concrete semantic identity through bindings and arguments. Arithmetic/comparison does not grant I/O authority; console is an explicit effect. Only the documented comparisons and generic constraint profiles apply. A TypeId does not synthesize a user-defined Eq/Ord, clone or drop implementation.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### operator:ratio-e280b1-7-False; expected 23

```nebo
start(){(7‱).q;flow.assert(q == 7‱);23.return;}
```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Additional observations and limits

```text
[
  {
    "base": 0,
    "case_id": "types:type-17",
    "category": "native-type",
    "flags": 2,
    "kind": 17,
    "observed_sha256": "02ebb4e933d7c0be874c2a05d4ba3534acc82c4fd916729fade9537184283542",
    "type_id": 17
  }
]
```

## Related entries

[Index](index.md)

- [type-Void](type-Void.md)

- [type-Bool](type-Bool.md)

- [type-Int](type-Int.md)

- [type-Text](type-Text.md)

## Provenance

- compiler/semantic/types/type_table.inc — SHA-256 a104864da8c77b21c4186ba1cdcf8d40800c464a8edbcccf31fc1ed57b4cf528

- compiler/semantic/types/type_table.asm — SHA-256 1c04c832d2df1cd5900cf37fa73aa91884c79d7754d1e85c8ce29fa473e227b3

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
