# ∏ — product binder

Product reduction.

```text
Identity: NSR-DOM-009 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: ACTIVE_BOUNDED
```

## Syntax or signature

```text
lexeme: ∏
context: finite collection/range reduction
fixity: binder
arity: 1+
precedence: BINDER
associativity: N/A
canonical_ascii: product()
operand_rule: finite iterable plus multiplicative expression
result_rule: type-specific product or reduction report
```

## Evaluation and types

domain once; explicit deterministic order. Short-circuit: NO. Operand rule: finite iterable plus multiplicative expression. Result rule: type-specific product or reduction report.

## Errors and remediation

checked overflow and empty-domain identity policy. Finite immutable Array&lt;Int,N&gt; domain; canonical checked constant fold in source order; empty identities 0/1; constant overflow is rejected with NEBO_TYPE_CONSTANT_OVERFLOW; later publication and explicit return remain in the shared Program. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

ACTIVE_BOUNDED in std.math.reduce. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Finite immutable Array&lt;Int,N&gt; domain; canonical checked constant fold in source order; empty identities 0/1; constant overflow is rejected with NEBO_TYPE_CONSTANT_OVERFLOW; later publication and explicit return remain in the shared Program. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Executed examples

### operator:reduce-e2888f-\[\]; expected 23

```nebo
start(){Array<Int,0> [].values;(∏values).console();23.return;}
```

Oracle: {"console_text_utf8": "1", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "5045fd7401798a3f5e5ff142ddaf301ef631f92a5499c4029fe3dd26e251335c"}

## Rejected examples

### operator:wrong-domain-e2888f; expected NEBO_TYPE_MISMATCH

```nebo
(Int.self)invalid(){(∏17).return;}start(){7.invalid().return;}
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
