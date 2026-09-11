# &amp;expr — address/reference prefix

RESERVED: Never active in the safe core without an explicit unsafe/FFI contract. The operand/result description records the rejected or reserved proposal; it is not executable permission.

```text
Identity: NSR-RES-017 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: RESERVED
```

## Syntax or signature

```text
lexeme: &expr
context: unsafe/FFI future profile
fixity: prefix
arity: 1
precedence: UNASSIGNED
associativity: right
canonical_ascii: explicit borrow/address API
operand_rule: lvalue with capability and lifetime proof
result_rule: typed reference/address
```

## Evaluation and types

operand place once. Short-circuit: NO. Operand rule: lvalue with capability and lifetime proof. Result rule: typed reference/address.

## Errors and remediation

unsafe capability required. Current native grammar/context only; no implicit activation. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

RESERVED in future.unsafe. Current native grammar/context only; no implicit activation. The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Rejected examples

### lexical:protected-15; expected NEBO_LEX_RESERVED_SYMBOL

```nebo
start(){17.value;29.other;&value;23.return;}
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
