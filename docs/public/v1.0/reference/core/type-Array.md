# Array

A fixed-length typed aggregate.

```text
Identity: type:Array (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Array
```

## Logical layout

Length and element type form its bounded identity; the current scalar profile admits length 0..256.

## Construction and members

Array&lt;Int,N&gt; \[elements\] or .filled(value); at/map preserve the declared extent.

## Protocols and ownership

Each element keeps its declared type and ownership. Positional/map operations must preserve the admitted aggregate shape; a successful scalar example does not grant arbitrary Copy/clone for owned elements. Borrowed element views remain bounded by the aggregate owner lifetime.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Executed examples

### composite:array-map-empty; expected 0

```nebo
callable keep(Int.value) capture none { value.return; }
start() { Array<Int, 0> [].a; a.map(keep).b; b.length(); }

```

Oracle: {"independent_builds": 2, "process_exit": 0, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### composite:array-map-wrong-type; expected NEBO_TYPE_MISMATCH

```nebo
callable keep(Bool.value) capture none { value.return; }
start() { Array<Int, 2> [4, 9].a; a.map(keep).b; b.at(0); }

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

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
