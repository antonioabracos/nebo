# diagnostic contract

Invalid source must reject before executable publication. Diagnostic code, severity, phase and half-open UTF-8 byte spans are contractual; JSON-lines schema 1 and SARIF/LSP projections preserve that identity. LSP positions use UTF-16.

```text
Identity: N1-diagnostic-contract (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-diagnostic-contract — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Invalid source must reject before executable publication. Diagnostic code, severity, phase and half-open UTF-8 byte spans are contractual; JSON-lines schema 1 and SARIF/LSP projections preserve that identity. LSP positions use UTF-16.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Rejected examples

### source:reject-return-type; expected NEBO_TYPE_MISMATCH

```nebo
start(){"wrong".return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Additional observations and limits

```text
[
  {
    "case_id": "diagnostics:usage-10",
    "category": "negative",
    "exit": 2
  },
  {
    "case_id": "diagnostics:usage-9",
    "category": "negative",
    "exit": 2
  }
]
```

## Related entries

[Index](index.md)

- [rule-allocation-budget](rule-allocation-budget.md)

- [rule-arithmetic-failures](rule-arithmetic-failures.md)

- [rule-output-capacity](rule-output-capacity.md)

- [rule-recursion-budget](rule-recursion-budget.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
