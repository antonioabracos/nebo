# Slice

A borrowed view constrained by its owner and generation.

```text
Identity: type:Slice (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Slice
Native TypeId: 13 (not SymbolId)
```

## Logical layout

A 40-byte descriptor aligned to 8 bytes in the current native profile. The view cannot outlive its owner or survive forbidden mutation/reset.

## Construction and members

borrowShared().asSlice() in the measured ownership profile; release derived views before the owner.

## Protocols and ownership

A Slice borrows its owner and records the admitted view extent/generation. It cannot escape the owner scope; release derived views before the originating borrow. A shared view excludes forbidden writes, while a unique borrow excludes aliases. The descriptor is not an owning clone.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Executed examples

### ownership:G004-02; expected 23

```nebo
// Shared borrows may coexist and derive shorter read-only views. A unique
// borrow is exclusive and may update the owner before an explicit release.
start() {
    "borrowed text".owner;
    owner.borrowShared().immutableBorrow;
    immutableBorrow.scope().lexicalScope;
    immutableBorrow.reborrow().shortBorrow;
    immutableBorrow.asSlice().byteView;
    shortBorrow.release().shortReleased;
    byteView.release().viewReleased;
    immutableBorrow.release().immutableReleased;

    7.mutableOwner;
    mutableOwner.borrowUnique().mutableBorrow;
    mutableBorrow.write(23).written;
    mutableBorrow.read().observed;
    mutableBorrow.release().mutableReleased;
    observed;
}

```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### ownership:borrow-escape; expected NEBO-LIFETIME-ESCAPE

```nebo
start() {
    5.owner;
    owner.borrowShared().view;
    view.return;
}

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-LIFETIME-ESCAPE"}

## Additional observations and limits

```text
[
  {
    "base": 0,
    "case_id": "types:type-13",
    "category": "native-type",
    "flags": 2,
    "kind": 13,
    "observed_sha256": "8efe2f30bfcb10c6e0b24ef386c3ff82a2bb842d545ea7824e9c46d529a391dd",
    "type_id": 13
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

- tests/rf204/G170/ownership_test.py — SHA-256 ed4f10840cdff23e8f7f520c0603208b18e27f2b31c346846bd9e805a2516e4d

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
