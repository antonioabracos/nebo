# |x| — absolute-value delimiters

RESERVED: Reserved because \`|\` already competes with patterns, probability and potential bitwise syntax. The operand/result description records the rejected or reserved proposal; it is not executable permission.

```text
Identity: NSR-RES-021 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: RESERVED
```

## Syntax or signature

```text
lexeme: |x|
context: future numeric grammar
fixity: delimited
arity: 1
precedence: UNASSIGNED
associativity: N/A
canonical_ascii: abs()
operand_rule: numeric value
result_rule: nonnegative numeric value
```

## Evaluation and types

operand once. Short-circuit: NO. Operand rule: numeric value. Result rule: nonnegative numeric value.

## Errors and remediation

reserved diagnostic. Current native grammar/context only; no implicit activation. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

RESERVED in future.math. Current native grammar/context only; no implicit activation. The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Rejected examples

### lexical:protected-19; expected NEBO_LEX_RESERVED_SYMBOL

```nebo
start(){17.value;29.other;|value|;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_LEX_RESERVED_SYMBOL"}

## Related entries

[Index](index.md)

- [operator-NSR-CORE-001](operator-NSR-CORE-001.md)

- [operator-NSR-CORE-002](operator-NSR-CORE-002.md)

- [operator-NSR-CORE-003](operator-NSR-CORE-003.md)

- [operator-NSR-CORE-004](operator-NSR-CORE-004.md)

## Provenance

- docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv — SHA-256 b7e5694ceadf30ccffb4077c994fe230d2a10201b64dc6e9e218bdcf4b157f14

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
