# std.prelude.console

Publish a typed value through the canonical Console surface.

```text
Identity: prelude:1:console (SERIALIZED_SYMBOL_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
Serialized SymbolId: 0xe388cf778a8af553
```

## Syntax or signature

```text
value.console()
```

## Origin and explicit import

Implicit origin: PRELUDE. Original module: std.console. Explicit alternative: import "std.console" { console; }.explicit; --no-prelude removes implicit visibility. Import every referenced prelude name explicitly; imports grant no capability.

## Behavior, methods and protocols

The retained document keeps typed nodes and payload bytes. Multiple publications retain lexical order. Int, Bool and Text have distinct node kinds. print is rejected.

## Ownership and effects

Publication is an explicit output effect. The retained document is observed locally by a binary trace oracle; this is not a claim of a live desktop display.

## Errors and limits

Wrong receiver/option types reject. Bounded document capacity and failure atomicity remain enforced; importing console grants no additional authority.

## Executed examples

### local:prelude-console; expected 59

```nebo
start(){61.console();59.return;}
```

Oracle: {"console_text_utf8": "61", "independent_builds": 2, "kinds": \[4\], "process_exit": 59, "runtime_sha256": "7a7a492f4e864290a94cb7557dddc5f4ae68224ccf8f54e1b9fb6f207d5917a0"}

## Rejected examples

### local:hidden-console; expected NEBO-RF166-G163-002

```nebo
start(){61.console();59.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-RF166-G163-002", "no_prelude": true}

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
  }
]
```

## Related entries

[Index](index.md)

- [Option](Option.md)

- [Result](Result.md)

- [Error](Error.md)

- [Ordering](Ordering.md)

## Provenance

- sdk/interfaces/prelude/std.prelude.ni — SHA-256 910170b1ccabf964a1186892ee9f4395f1b52c1e6b5cc7683f68ee2904de0933

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
