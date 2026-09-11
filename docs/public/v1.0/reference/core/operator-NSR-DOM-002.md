# ∛ — cube root

Cube root with exact/approximate behavior determined by the numeric type.

```text
Identity: NSR-DOM-002 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: ACTIVE_BOUNDED
```

## Syntax or signature

```text
lexeme: ∛
context: numeric/math profile
fixity: prefix
arity: 1
precedence: P150_PREFIX
associativity: right
canonical_ascii: cubeRoot()
operand_rule: CubeRoot protocol
result_rule: type-specific root or Result
```

## Evaluation and types

operand once. Short-circuit: NO. Operand rule: CubeRoot protocol. Result rule: type-specific root or Result.

## Errors and remediation

domain and precision explicit. Native checked exact signed Int roots; nonintegral/invalid real roots trap through the arithmetic domain owner. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

ACTIVE_BOUNDED in std.math. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Native checked exact signed Int roots; nonintegral/invalid real roots trap through the arithmetic domain owner. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Executed examples

### operator:root-e2889b-0; expected 23

```nebo
(Int.value)calculate(){(∛value).return;}start(){(0).calculate().console();23.return;}
```

Oracle: {"console_text_utf8": "0", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "c88c7d22bff223346890bdb5b122a89860b3aced684fcdafc6675d64140f1f66"}

## Rejected examples

### operator:wrong-unary-e2889b; expected NEBO_TYPE_MISMATCH

```nebo
(Int.self)invalid(){(∛true).return;}start(){17.invalid().console();23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [operator-NSR-CORE-001](operator-NSR-CORE-001.md)

- [operator-NSR-CORE-002](operator-NSR-CORE-002.md)

- [operator-NSR-CORE-003](operator-NSR-CORE-003.md)

- [operator-NSR-CORE-004](operator-NSR-CORE-004.md)

## Provenance

- docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv — SHA-256 b7e5694ceadf30ccffb4077c994fe230d2a10201b64dc6e9e218bdcf4b157f14

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
