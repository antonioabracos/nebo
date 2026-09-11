# Result

A typed success or failure with one active payload.

```text
Identity: type:Result (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Result
```

## Logical layout

A discriminant selects one active Ok(T) or Err(E) payload. The inactive side is not a value.

## Construction and members

Result&lt;T,E&gt;(Ok(value)) | Result&lt;T,E&gt;(Err(error)). isOk/isErr distinguish variants. get/expect observe Ok; getErr/expectErr require Err. The measured value-form map(43), mapErr(47), andThen(Ok(53)) and orElse(Ok(61)) preserve the selected payload type; arbitrary effectful callbacks are not implied.

## Protocols and ownership

Owns the active T or E. Propagation selects the active error route and does not implicitly discard live resources.

## Errors, limits and target

Wrong-side observers and incompatible fallback/callback types reject in the bounded profile. Imported metadata cannot supply executable payloads. The executed target is x86_64 Linux System V ELF; no foreign ABI layout is implied.

## Executed examples

### local:prelude-Result; expected 37

```nebo
start(){Result<Int,Int>(Ok(37)).x;x.get().return;}
```

Oracle: {"independent_builds": 2, "process_exit": 37, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### optionresult:result-expect-wrong-side; expected NEBO_BEHAVIOR_NOT_SUPPORTED

```nebo
start() {
    Result<Int,Int>(Err(13)).failure;
    failure.expect("success required").return;
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
