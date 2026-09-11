# Int

A signed 64-bit integer with checked ordinary arithmetic.

```text
Identity: type:Int (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Int
Native TypeId: 3 (not SymbolId)
```

## Logical layout

Eight-byte signed value; no implicit Float or Bool coercion.

## Construction and members

Radix/separator literals; arithmetic, comparison, wrapping/checked methods in their admitted profiles.

## Protocols and ownership

The Int value preserves its concrete semantic identity through bindings and arguments. Arithmetic/comparison does not grant I/O authority; console is an explicit effect. Only the documented comparisons and generic constraint profiles apply. A TypeId does not synthesize a user-defined Eq/Ord, clone or drop implementation.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Executed examples

### binding:Int-0-typed; expected 23

```nebo
start(){Int.value;37.value;value.console();23.return;}
```

Oracle: {"console_text_utf8": "37", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "b5bcc903c755e76bcd44796e0c9a73bc00a30900436647160f53337f2ca1df09"}

## Rejected examples

### semantics:no-coercion-Int; expected NEBO_TYPE_MISMATCH

```nebo
start(){Int.x;true.x;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Additional observations and limits

```text
[
  {
    "base": 0,
    "case_id": "types:type-3",
    "category": "native-type",
    "flags": 1,
    "kind": 3,
    "observed_sha256": "340155d51420a32607bc896b6f7e65cf178f2d9b77db7fba72ca11e1cce7df70",
    "type_id": 3
  }
]
```

## Related entries

[Index](index.md)

- [type-Void](type-Void.md)

- [type-Bool](type-Bool.md)

- [type-Text](type-Text.md)

- [type-Console](type-Console.md)

## Provenance

- compiler/semantic/types/type_table.inc — SHA-256 a104864da8c77b21c4186ba1cdcf8d40800c464a8edbcccf31fc1ed57b4cf528

- compiler/semantic/types/type_table.asm — SHA-256 1c04c832d2df1cd5900cf37fa73aa91884c79d7754d1e85c8ce29fa473e227b3

- tests/rf204/G170/binding_test.py — SHA-256 e030e23aab8fa49674e14b4cf50af041571cb97954f7fbb0873f0bed3b3eab39

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
