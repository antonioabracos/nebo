# (a, b, c) as comma operator — free comma sequencing

REJECTED: Comma remains a separator and never discards intermediate expression results as an operator. The operand/result description records the rejected or reserved proposal; it is not executable permission.

```text
Identity: NSR-REJ-010 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: REJECTED
```

## Syntax or signature

```text
lexeme: (a, b, c) as comma operator
context: general expression
fixity: infix
arity: 2+
precedence: N/A
associativity: left
canonical_ascii: explicit block or pipeline
operand_rule: N/A
result_rule: N/A
```

## Evaluation and types

N/A. Short-circuit: NO. Operand rule: N/A. Result rule: N/A.

## Errors and remediation

diagnostic. Current native grammar/context only; no implicit activation. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

REJECTED in core.control. Current native grammar/context only; no implicit activation. The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Rejected examples

### lexical:protected-32; expected NEBO_PARSE_EXPECTED_TOKEN

```nebo
start(){17.value;29.other;(1,2,3);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_PARSE_EXPECTED_TOKEN"}

## Related entries

[Index](index.md)

- [operator-NSR-CORE-001](operator-NSR-CORE-001.md)

- [operator-NSR-CORE-002](operator-NSR-CORE-002.md)

- [operator-NSR-CORE-003](operator-NSR-CORE-003.md)

- [operator-NSR-CORE-004](operator-NSR-CORE-004.md)

## Provenance

- docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv — SHA-256 b7e5694ceadf30ccffb4077c994fe230d2a10201b64dc6e9e218bdcf4b157f14

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
