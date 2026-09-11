# Color

An RGBA value with checked channels and explicit Console roles.

```text
Identity: type:Color (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Color
Native TypeId: 7 (not SymbolId)
```

## Logical layout

Four logical channels in 0..255. Alpha defaults to opaque for rgb; this is a value, not a capability.

## Construction and members

Color.rgb/rgba/hex/parseHex; red/green/blue/alpha, equals, withAlpha, hash and serializers in the measured profile.

## Protocols and ownership

The Color value preserves its concrete semantic identity through bindings and arguments. Arithmetic/comparison does not grant I/O authority; console is an explicit effect. Only the documented comparisons and generic constraint profiles apply. A TypeId does not synthesize a user-defined Eq/Ord, clone or drop implementation.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Executed examples

### console:typed-color; expected 23

```nebo
start(){Color.c;Color.rgb(17,29,53).c;c.red().console();23.return;}
```

Oracle: {"console_text_utf8": "17", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "publications": 1, "runtime_sha256": "ef63802d6adb274672ff60210fb3e604b8b8a8cb20f791d1a031c8b9da9add38"}

## Rejected examples

### console:rgb-type; expected NEBO_TYPE_MISMATCH

```nebo
start(){Color.rgb(17,true,53);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Additional observations and limits

```text
[
  {
    "base": 0,
    "case_id": "types:type-7",
    "category": "native-type",
    "flags": 18,
    "kind": 7,
    "observed_sha256": "15384c3a7d704edc359426b5231796e8e8ad435d04cdf5749b2facce552873b1",
    "type_id": 7
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

- tests/rf204/G170/console_public_test.py — SHA-256 4ff1b67ea212ce82443057d944c9993e64ad919fe90faadb19f0cb6014f4cff5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
