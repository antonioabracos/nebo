# Option

A typed optional value with distinct present and absent variants.

```text
Identity: type:Option (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Option
```

## Logical layout

A discriminant selects Some with one T payload or None with no payload. No inactive payload is accessible.

## Construction and members

Option&lt;T&gt;(Some(value)) | Option&lt;T&gt;(None()). Some carries T; None carries no payload. isSome/isNone inspect the tag; get/expect observe a present payload; unwrapOr supplies an eager value fallback. In the measured value-form vertical, map(31) replaces a present payload, andThen(Some(41)) selects a typed variant and orElse(37) supplies an absent value. This does not promise arbitrary effectful user callbacks.

## Protocols and ownership

Owns its active payload. Copy/borrow permission follows T; unwrapOr evaluates its argument even when Some is active.

## Errors, limits and target

Wrong payload and observer types reject. None has no payload binding. An invalid expect/get must not be treated as a successful value. The executed target is x86_64 Linux System V ELF; no foreign ABI layout is implied.

## Executed examples

### local:prelude-Option; expected 31

```nebo
start(){Option<Int>(Some(31)).x;x.unwrapOr(7).return;}
```

Oracle: {"independent_builds": 2, "process_exit": 31, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### optionresult:option-expect-none; expected NEBO_BEHAVIOR_NOT_SUPPORTED

```nebo
start() {
    Option<Int>(None()).missing;
    missing.expect("a value is required").return;
}

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_BEHAVIOR_NOT_SUPPORTED"}

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
