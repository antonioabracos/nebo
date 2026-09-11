# allocation budget

System blocks &lt;=65536 bytes, arena capacity &lt;=1048576; OOM releases earlier successful allocations without publishing a later sink.

```text
Identity: N1-allocation-budget (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-allocation-budget — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

System blocks &lt;=65536 bytes, arena capacity &lt;=1048576; OOM releases earlier successful allocations without publishing a later sink.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### ownership:arena-1048576-17; expected 23

```nebo
start(){Arena.withCapacity(1048576).a;a.allocate<Int>(17).b;a.reset().r;23.return;}
```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "90d30fad835779008da8f17851c4f2b576b8d268e6f40c5d88535f162092a7d6"}

## Related entries

[Index](index.md)

- [rule-arithmetic-failures](rule-arithmetic-failures.md)

- [rule-output-capacity](rule-output-capacity.md)

- [rule-recursion-budget](rule-recursion-budget.md)

- [rule-publication-atomicity](rule-publication-atomicity.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/ownership_test.py — SHA-256 ed4f10840cdff23e8f7f520c0603208b18e27f2b31c346846bd9e805a2516e4d

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
