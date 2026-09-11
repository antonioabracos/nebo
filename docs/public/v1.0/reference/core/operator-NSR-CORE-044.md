# …&lt; — range excluding end

Half-open range \`\[start,end)\`.

```text
Identity: NSR-CORE-044 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: ACTIVE
```

## Syntax or signature

```text
lexeme: …<
context: between ordered endpoints
fixity: infix
arity: 2
precedence: P125_RANGE
associativity: non-associative
canonical_ascii: Range.exclusiveEnd
operand_rule: compatible ordered step-capable endpoints
result_rule: Range<T> including start and excluding end
```

## Evaluation and types

start then end exactly once. Short-circuit: NO. Operand rule: compatible ordered step-capable endpoints. Result rule: Range&lt;T&gt; including start and excluding end.

## Errors and remediation

Range policy. Current native grammar/context only; no implicit activation. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

ACTIVE in core.range. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Int64/Bool/binary64 or the referenced public typed profile; native checked arithmetic and complete source statement ownership. Int64/Bool/binary64/Unicode scalar values; checked arithmetic; lexical evaluation once The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Executed examples

### operator:range-e280a63c-0; expected 23

```nebo
start(){(0…<4).values;values.length().console();23.return;}
```

Oracle: {"console_text_utf8": "4", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "24376fee255443343dd82183aec0410bb84abdd51e022adce77caacd30fc3b11"}

## Rejected examples

### operator:ascii-three-dot-range; expected NEBO_LEX_RESERVED_SYMBOL

```nebo
start() {
    (1...3).progression;
    progression.length().return;
}

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

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/semantic/bindings/binding_vertical.asm — SHA-256 47e3a89c66a2251ca2b8c30eb3faa17078d71a74751d9aafe2ae89f9d23561ce

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
