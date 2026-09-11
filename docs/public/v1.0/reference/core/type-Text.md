# Text

Immutable UTF-8 text with explicit byte, scalar and grapheme units.

```text
Identity: type:Text (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Text
Native TypeId: 4 (not SymbolId)
```

## Logical layout

Logical byte pointer and length; a 16-byte descriptor in the current layout. Ownership belongs to the retained bytes.

## Construction and members

Quoted/raw/multiline literals; byteLength, codepointCount and typed textual methods.

## Protocols and ownership

The descriptor refers to retained UTF-8 text data. Derived views remain bound to the owner lifetime; release child views before their parent. Binding a descriptor does not authorize mutation or extend borrowed storage. Explicit textual/byte operations preserve their documented byte or scalar units.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Executed examples

### binding:Text-0-typed; expected 23

```nebo
start(){Text.value;"Nebo".value;value.byteLength().console();value.codepointCount().console();23.return;}
```

Oracle: {"console_text_utf8": "44", "independent_builds": 2, "kinds": \[4, 4\], "process_exit": 23, "runtime_sha256": "741e190e1b6623950fa09d21b76147b73a06586dc8a7859a3d5fbfdfc4427877"}

## Rejected examples

### semantics:no-coercion-Text; expected NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH

```nebo
start(){Text.x;17.x;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH"}

## Additional observations and limits

```text
[
  {
    "base": 0,
    "case_id": "types:type-4",
    "category": "native-type",
    "flags": 1,
    "kind": 4,
    "observed_sha256": "90e10f61e04c43442b608d0e1ce589c6faa0e63ae93f6dcba593dfb871f3bb3e",
    "type_id": 4
  }
]
```

## Related entries

[Index](index.md)

- [type-Void](type-Void.md)

- [type-Bool](type-Bool.md)

- [type-Int](type-Int.md)

- [type-Console](type-Console.md)

## Provenance

- compiler/semantic/types/type_table.inc — SHA-256 a104864da8c77b21c4186ba1cdcf8d40800c464a8edbcccf31fc1ed57b4cf528

- compiler/semantic/types/type_table.asm — SHA-256 1c04c832d2df1cd5900cf37fa73aa91884c79d7754d1e85c8ce29fa473e227b3

- tests/rf204/G170/binding_test.py — SHA-256 e030e23aab8fa49674e14b4cf50af041571cb97954f7fbb0873f0bed3b3eab39

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
