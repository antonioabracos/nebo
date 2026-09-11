# ⊼ — NAND

Boolean NAND; unlike \`&amp;&amp;\`, it does not short-circuit.

```text
Identity: NSR-DOM-068 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: ACTIVE_BOUNDED
```

## Syntax or signature

```text
lexeme: ⊼
context: formal Boolean profile
fixity: infix
arity: 2
precedence: P090_AND
associativity: left
canonical_ascii: nand
operand_rule: Bool operands
result_rule: Bool
```

## Evaluation and types

both operands exactly once. Short-circuit: NO. Operand rule: Bool operands. Result rule: Bool.

## Errors and remediation

non-Bool rejected. Finite domain partition/result grammar, explicit proof/model status and budget; exhaustive Boolean truth tables; unknown and timeout remain distinct outcomes; this does not claim an automatic theorem prover. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

ACTIVE_BOUNDED in std.logic. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Finite domain partition/result grammar, explicit proof/model status and budget; exhaustive Boolean truth tables; unknown and timeout remain distinct outcomes; this does not claim an automatic theorem prover. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Executed examples

### boundedoperator:dom-068-0-0-True; expected 1

```nebo
start(){nand(0 ⊼ 0,7).value();}
```

Oracle: {"independent_builds": 2, "process_exit": 1, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### boundedoperator:dom-068-negative; expected NEBO_TYPE_UNSUPPORTED_OPERATOR

```nebo
start(){nand(2,0,7).value();}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_UNSUPPORTED_OPERATOR"}

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

- tests/rf204/G170/bounded_operator_test.py — SHA-256 a756e75fb059c5f5837b1ab76490c31b8e92762f0400cad0d2545ff0532beaf5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
