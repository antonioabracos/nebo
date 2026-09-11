# std.prelude.Iterator

The prelude iteration protocol associated with admitted for iteration.

```text
Identity: prelude:1:Iterator (SERIALIZED_SYMBOL_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
Serialized SymbolId: 0xaf1313c7a67a4790
```

## Syntax or signature

```text
for (item in boundRange) { item.console(); }
```

## Origin and explicit import

Implicit origin: PRELUDE. Original module: std.core. Explicit alternative: import "std.core" { Iterator; }.explicit; --no-prelude removes implicit visibility. Import every referenced prelude name explicitly; imports grant no capability.

## Behavior, methods and protocols

The bounded source profile iterates an already bound iterable and applies break/continue and the optional finite filter. Iterator is a protocol identity, not a public Iterator(...) constructor.

## Ownership and effects

Iteration must respect the owner lifetime and cleanup of the iterable. The protocol import grants no capability.

## Errors and limits

No arbitrary iterator constructor or generic Iterator constraint is promised. Disabling the prelude removes the protocol from the injected resolver; Range must be explicitly imported for the example.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### local:prelude-Iterator; expected 14

```nebo
start(){Range.exclusive(2,6).items;0.total.mutable;for(item in items){total+=item;}total.return;}
```

Oracle: {"independent_builds": 2, "process_exit": 14, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

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
    "case_id": "local:hidden-Iterator",
    "category": "SDK",
    "enabled_symbol_id": "0xaf1313c7a67a4790",
    "injected_when_disabled": false,
    "scope": "resolver visibility; no public named constructor"
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
