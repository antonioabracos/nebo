# error identity

Error code/category/span/context and cause remain structured; messages are derived from active error identity and caller context.

```text
Identity: N1-error-identity (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-error-identity — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Error code/category/span/context and cause remain structured; messages are derived from active error identity and caller context.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### optionresult:error-diagnostic-span; expected 17

```nebo
start() {
    Error(7103, 4, 52, 1, 3, 0).root;
    root.toDiagnostic(Span(11, 17)).diagnostic;
    diagnostic.spanEnd().return;
}

```

Oracle: {"independent_builds": 2, "process_exit": 17, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

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

- [rule-move](rule-move.md)

- [rule-copy-clone](rule-copy-clone.md)

- [rule-borrow-aliasing](rule-borrow-aliasing.md)

- [rule-lifetime-escape](rule-lifetime-escape.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/option_result_test.py — SHA-256 b91cfdcf0a149083e241308f7ced2c95532758131a3b0d9d15297e026cff81fc

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
