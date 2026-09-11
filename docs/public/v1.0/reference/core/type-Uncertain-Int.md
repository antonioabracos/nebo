# Uncertain&lt;Int&gt;

A bounded uncertainty/measurement carrier for Int.

```text
Identity: type:Uncertain<Int> (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Uncertain<Int>
Native TypeId: 20 (not SymbolId)
```

## Logical layout

One qword in the bounded runtime carrier, distinct in semantic analysis.

## Construction and members

The admitted uncertainty profile owns construction and operations; no general symbolic statistics type is implied.

## Protocols and ownership

The Uncertain&lt;Int&gt; value preserves its concrete semantic identity through bindings and arguments. Arithmetic/comparison does not grant I/O authority; console is an explicit effect. Only the documented comparisons and generic constraint profiles apply. A TypeId does not synthesize a user-defined Eq/Ord, clone or drop implementation.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### operator:uncertain-value-17-3; expected 23

```nebo
start(){(17 ± 3).m;m.measuredValue().console();m.uncertainty().console();23.return;}
```

Oracle: {"console_text_utf8": "173", "independent_builds": 2, "kinds": \[4, 4\], "process_exit": 23, "runtime_sha256": "7b9a75d7ae99a43c6ecda09cbf368d81257a1d32678de49dd45a4ccb6f4c936d"}

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
