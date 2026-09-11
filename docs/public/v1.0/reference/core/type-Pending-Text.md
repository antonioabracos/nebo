# Pending&lt;Text&gt;

An internal pending-text result identity used by input typing.

```text
Identity: type:Pending<Text> (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Pending<Text>
Native TypeId: 6 (not SymbolId)
```

## Logical layout

Semantic pending descriptor; no independent public constructor or general-purpose async type is implied.

## Construction and members

Obtain typed input through scan; use the resolved payload in the admitted Scan profile.

## Protocols and ownership

The pending wrapper retains Text as its base TypeId. This native identity does not implicitly resolve asynchronous input or extend a payload lifetime. Use the documented Scan/input plan for observed values; no public Pending(...) constructor is promised.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### scan:int-23-return-23; expected 23

```nebo
start(){"Age: ".scan(.int(),.mock("23")).console();23.return;}
```

Oracle: {"console_text_utf8": "23", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "78067f1881f6b0d063fd8262518ca5706c32ce03063d879e24c9a24380bfa337"}

## Additional observations and limits

```text
[
  {
    "case_id": "metadata:prelude-declarations",
    "category": "metadata",
    "declarations": 11,
    "interface_sha256": "910170b1ccabf964a1186892ee9f4395f1b52c1e6b5cc7683f68ee2904de0933",
    "symbol_ids": [
      "0xb479812d2b532b1f",
      "0xa827441931b3ac13",
      "0x4f5f6793880ecdcc",
      "0x6134016fa73ad75e",
      "0xbbaa81a7272b4f17",
      "0x334a76a70563dd44",
      "0x34c249cdf79d7ac9",
      "0xaf1313c7a67a4790",
      "0xbd6f63ce5a3969ee",
      "0xe388cf778a8af553",
      "0x1c582e96c672743f"
    ]
  },
  {
    "base": 4,
    "case_id": "types:type-6",
    "category": "native-type",
    "flags": 6,
    "kind": 6,
    "observed_sha256": "01e3601385a1592c01237e22356e61297406e27cbd6eb4533fbd45fd7b9635f3",
    "type_id": 6
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

- tests/rf204/G170/scan_public_test.py — SHA-256 e487ed7a7709494b21d44b475371945fa537edb1ce2850f8719f76381b3e7e35

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
