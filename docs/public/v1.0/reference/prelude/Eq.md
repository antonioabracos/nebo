# std.prelude.Eq

The prelude equality protocol in the admitted scalar generic constraints.

```text
Identity: prelude:1:Eq (SERIALIZED_SYMBOL_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
Serialized SymbolId: 0x334a76a70563dd44
```

## Syntax or signature

```text
generic<T> (T.value)hold() where T: Hash + Eq { value.return; }
```

## Origin and explicit import

Implicit origin: PRELUDE. Original module: std.core. Explicit alternative: import "std.core" { Eq; }.explicit; --no-prelude removes implicit visibility. Import every referenced prelude name explicitly; imports grant no capability.

## Behavior, methods and protocols

Equal values agree under the admitted equality owner. Hash + Eq is the measured dictionary/generic constraint profile; names alone do not supply arbitrary user implementations.

## Ownership and effects

No capability grant. The receiver type determines copy and lifetime behavior; comparing values does not transfer ownership.

## Errors and limits

Incompatible generic arguments and malformed constraints reject. An Eq import is visibility, not a new operator implementation.

## Executed examples

### local:prelude-Eq; expected 47

```nebo
generic<T> (T.value)hold() where T: Hash + Eq {value.return;}start(){47.hold().return;}
```

Oracle: {"independent_builds": 2, "process_exit": 47, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### local:hidden-Eq; expected NEBO-RF166-G163-002

```nebo
generic<T> (T.value)hold() where T: Hash + Eq {value.return;}start(){47.hold().return;}
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
