# publication atomicity

Failure before an atomic sink preserves existing files; rename/capacity/parser failures leave no partial output.

```text
Identity: N1-publication-atomicity (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-publication-atomicity — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Failure before an atomic sink preserves existing files; rename/capacity/parser failures leave no partial output.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### composition:filesystem-rename-failure; expected 175

```nebo
import "std.fs" { Path; File; }.fs;start(){"new content".s;File.writeText(Path.parse("target"),s,utf8,atomic);23.return;}
```

Oracle: {"expected_files": {}, "independent_builds": 2, "inputs": {"target/marker": "756e6368616e676564"}, "process_exit": 175, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Related entries

[Index](index.md)

- [rule-allocation-budget](rule-allocation-budget.md)

- [rule-arithmetic-failures](rule-arithmetic-failures.md)

- [rule-output-capacity](rule-output-capacity.md)

- [rule-recursion-budget](rule-recursion-budget.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
