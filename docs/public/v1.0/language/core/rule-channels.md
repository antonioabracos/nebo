# channels

Within the separately measured material profile, without stable-availability promotion: Bounded FIFO transport preserves values, capacity errors and close behavior; source loops compose with independent random states.

```text
Identity: N1-channels (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: NORMATIVE_BOUNDARY_OF_MATERIAL_NON_STABLE_PROFILE
```

## Syntax or signature

```text
N1-channels — NORMATIVE_BOUNDARY_OF_MATERIAL_NON_STABLE_PROFILE
```

## Scope and constraints

Within the separately measured material profile, without stable-availability promotion: Bounded FIFO transport preserves values, capacity errors and close behavior; source loops compose with independent random states.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### source:S05; expected 23

```nebo
// Single-consumer tasks and bounded FIFO retain their distinct values.
(Int.index)calculate(){(index+59).return;}
start(){Task.spawn(calculate).future;Channel<Int>.bounded(2).queue;queue.trySend(73).get();future.await().get().console();queue.tryReceive().get().console();queue.close();23.return;}

```

Oracle: {"console_text_utf8": "5973", "independent_builds": 2, "kinds": \[4, 4\], "process_exit": 23, "runtime_sha256": "709a2e4d590c50e575c92406373b3ea8a6194b89902de21da3fef5ce5a2b0918"}

## Additional observations and limits

```text
[
  {
    "binary_sha256": "0422d21ce3d49df708b897a30e83685837324acb2914d74a9b072c6fa2db7a45",
    "case_id": "semantic-native:channel",
    "proof_kind": "native assertions over real owner state; not public source admission"
  }
]
```

## Related entries

[Index](index.md)

- [rule-move](rule-move.md)

- [rule-copy-clone](rule-copy-clone.md)

- [rule-borrow-aliasing](rule-borrow-aliasing.md)

- [rule-lifetime-escape](rule-lifetime-escape.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
