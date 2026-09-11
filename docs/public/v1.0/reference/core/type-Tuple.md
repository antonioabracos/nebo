# Tuple

A positional typed aggregate.

```text
Identity: type:Tuple (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Tuple
```

## Logical layout

Each position retains its own type and admitted layout.

## Construction and members

Tuple.of(values); positional operations require a compile-time valid position.

## Protocols and ownership

Each element keeps its declared type and ownership. Positional/map operations must preserve the admitted aggregate shape; a successful scalar example does not grant arbitrary Copy/clone for owned elements. Borrowed element views remain bounded by the aggregate owner lifetime.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Executed examples

### composite:tuple-map; expected 12

```nebo
struct Pair { Int.first; Int.second; }
(Int.self)addTwo() { (self + 2).return; }
(Int.self)addThree() { (self + 3).return; }
start() { Tuple.of(4, 9).p; p.mapEach(addTwo, addThree).q; q.toStruct<Pair>().r; r.second; }

```

Oracle: {"independent_builds": 2, "process_exit": 12, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### composite:tuple-map-wrong-type; expected NEBO_TUPLE_INVALID_RECEIVER

```nebo
(Bool.self)keep() { self.return; }
start() { Tuple.of(17, 29).p; p.mapEach(keep, keep).q; q.at<0>(); }

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TUPLE_INVALID_RECEIVER"}

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
