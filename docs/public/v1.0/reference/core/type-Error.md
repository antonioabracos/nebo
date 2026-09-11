# Error

A structured diagnostic value with retained identity and context.

```text
Identity: type:Error (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Error
```

## Logical layout

Six integer context fields (code, category, sourceId, spanStart, spanEnd, causeId) plus the bounded retained contextual message; the public constructor order is listed below.

## Construction and members

Error(code, category, sourceId, spanStart, spanEnd, causeId). code/category/source/span/cause fields preserve their typed integer values. message renders the category; withContext produces contextual messages without overwriting another live Error.

## Protocols and ownership

Owns retained contextual text. Inspection does not publish output; console is an explicit sink.

## Errors, limits and target

Invalid spans or argument types reject. Context message capacity is bounded; the current measured pool boundary is 4084 context bytes for the filesystem message prefix. The executed target is x86_64 Linux System V ELF; no foreign ABI layout is implied.

## Executed examples

### local:prelude-Error; expected 41

```nebo
start(){Error(7101,1,50,2,8,0).x;x.code().console();41.return;}
```

Oracle: {"console_text_utf8": "7101", "independent_builds": 2, "kinds": \[4\], "process_exit": 41, "runtime_sha256": "d1a5fa4b276abef6cff544eb3d3ab11a8b64bbe1156b43f77269ee27f764423c"}

## Rejected examples

### optionresult:error-invalid-diagnostic-span; expected NEBO_TYPE_MISMATCH

```nebo
start() {
    Error(7104, 1, 53, 1, 3, 0).root;
    root.toDiagnostic(Span(19, 7)).diagnostic;
    diagnostic.spanStart().return;
}

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

- tests/rf204/G170/option_result_test.py — SHA-256 b91cfdcf0a149083e241308f7ced2c95532758131a3b0d9d15297e026cff81fc

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
