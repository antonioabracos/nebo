# Range

A bounded integer progression with explicit endpoint policy.

```text
Identity: type:Range (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Range
```

## Logical layout

A bounded integer progression with start/end and endpoint policy; length and membership are derived from those values. The descriptor is not an Array of eagerly allocated members.

## Construction and members

Range.exclusive(start, end) | Range.inclusive(start, end). length counts members; contains tests membership. The four Unicode endpoint forms retain their exact inclusive/exclusive meaning. Bind an iterable before using it in for.

## Protocols and ownership

Value descriptor; iteration borrows the admitted range profile and observes each selected member once.

## Errors, limits and target

Zero step, invalid direction, overflow or unsupported scalar types reject. for does not admit an arbitrary inline expression as its iterable. The executed target is x86_64 Linux System V ELF; no foreign ABI layout is implied.

## Executed examples

### local:prelude-Range; expected 5

```nebo
start(){Range.exclusive(3,8).x;x.length().return;}
```

Oracle: {"independent_builds": 2, "process_exit": 5, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### composite:range-zero-step; expected NEBO_LIMIT_EXCEEDED

```nebo
start() {
    Range.exclusive(2, 10).stepBy(0).progression;
    progression.length().return;
}

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_LIMIT_EXCEEDED"}

## Related entries

[Index](index.md)

- [type-Void](type-Void.md)

- [type-Bool](type-Bool.md)

- [type-Int](type-Int.md)

- [type-Text](type-Text.md)

## Provenance

- compiler/semantic/types/type_table.inc — SHA-256 a104864da8c77b21c4186ba1cdcf8d40800c464a8edbcccf31fc1ed57b4cf528

- compiler/semantic/types/type_table.asm — SHA-256 1c04c832d2df1cd5900cf37fa73aa91884c79d7754d1e85c8ce29fa473e227b3

- tests/rf204/G170/composite_test.py — SHA-256 55ac93ae5384e68a22489d0b68dbd8acc1cb83ed7fdb2b3b2a1b5c71de6f01f3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
