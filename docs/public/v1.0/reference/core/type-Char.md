# Char

One Unicode scalar value, distinct from a byte and Text.

```text
Identity: type:Char (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Char
Native TypeId: 10 (not SymbolId)
```

## Logical layout

Four-byte scalar storage in the current native layout. Surrogates and invalid scalar literals reject.

## Construction and members

Single-quoted literal; codepoint() returns its integer scalar value.

## Protocols and ownership

The Char value preserves its concrete semantic identity through bindings and arguments. Arithmetic/comparison does not grant I/O authority; console is an explicit effect. Only the documented comparisons and generic constraint profiles apply. A TypeId does not synthesize a user-defined Eq/Ord, clone or drop implementation.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Executed examples

### binding:Char-0-typed; expected 23

```nebo
start(){Char.value;'Q'.value;value.codepoint().console();23.return;}
```

Oracle: {"console_text_utf8": "81", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "4d2bb620f42fd83b4813724cffd980bd458929948aa6e8437c25c25cec693bfd"}

## Rejected examples

### binding:char-codepoint-arity; expected NEBO_TYPE_MISMATCH

```nebo
start(){'Q'.value;value.codepoint(1).return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Additional observations and limits

```text
[
  {
    "base": 0,
    "case_id": "types:type-10",
    "category": "native-type",
    "flags": 1,
    "kind": 10,
    "observed_sha256": "c43dcf238d2ab744237f0aaf4928092222bfbce5b99905be6f7f6fe48add47d6",
    "type_id": 10
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

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
