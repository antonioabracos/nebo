# Bytes

A byte sequence with unsigned elements widened to Int on read.

```text
Identity: type:Bytes (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Bytes
Native TypeId: 11 (not SymbolId)
```

## Logical layout

Logical address and byte length; retain the owner lifetime for its bytes.

## Construction and members

Bytes.empty/fromByte/fromValues; byteLength and at. There is no separate Byte(...) constructor in this profile.

## Protocols and ownership

The descriptor refers to retained byte data. Derived views remain bound to the owner lifetime; release child views before their parent. Binding a descriptor does not authorize mutation or extend borrowed storage. Explicit textual/byte operations preserve their documented byte or scalar units.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Executed examples

### binding:Bytes-0-typed; expected 23

```nebo
start(){Bytes.value;Bytes.fromValues(17,29,71,83).value;value.at(2).console();value.byteLength().console();23.return;}
```

Oracle: {"console_text_utf8": "714", "independent_builds": 2, "kinds": \[4, 4\], "process_exit": 23, "runtime_sha256": "11e37ecb76d511832086507f56664ed0ae8db2389ce803b9250956da4af6aa5f"}

## Rejected examples

### binding:bytes-at-type; expected NEBO_TYPE_MISMATCH

```nebo
start(){Bytes.fromByte(17).value;value.at(true).return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Additional observations and limits

```text
[
  {
    "base": 0,
    "case_id": "types:type-11",
    "category": "native-type",
    "flags": 1,
    "kind": 11,
    "observed_sha256": "6f8abc2ce6b717c8bf070483b90cf7a649b1a7c2418d8a3714d1cdd5366ec9e4",
    "type_id": 11
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
