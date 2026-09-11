# /*...*/ — block comment

Line comments are canonical; block comments remain reserved, not silently ignored.

```text
Identity: NSR-RES-009 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: ACTIVE_TRIVIA
```

## Syntax or signature

```text
lexeme: /*...*/
context: lexer outside literals
fixity: lexical
arity: N
precedence: LEXICAL
associativity: N/A
canonical_ascii: N/A
operand_rule: comment bytes
result_rule: no tokens
```

## Evaluation and types

lexical. Short-circuit: NO. Operand rule: comment bytes. Result rule: no tokens.

## Errors and remediation

current explicit unsupported diagnostic. Current native grammar/context only; no implicit activation. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

ACTIVE_TRIVIA in future.lexer. Current native grammar/context only; no implicit activation. The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Rejected examples

### lexical:protected-10; expected NEBO_LEX_RESERVED_SYMBOL

```nebo
start(){17.value;29.other;~;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_LEX_RESERVED_SYMBOL"}

## Additional observations and limits

```text
[
  {
    "case_id": "lexical:trivia"
  }
]
```

## Related entries

[Index](index.md)

- [operator-NSR-CORE-001](operator-NSR-CORE-001.md)

- [operator-NSR-CORE-002](operator-NSR-CORE-002.md)

- [operator-NSR-CORE-003](operator-NSR-CORE-003.md)

- [operator-NSR-CORE-004](operator-NSR-CORE-004.md)

## Provenance

- docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv — SHA-256 b7e5694ceadf30ccffb4077c994fe230d2a10201b64dc6e9e218bdcf4b157f14

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
