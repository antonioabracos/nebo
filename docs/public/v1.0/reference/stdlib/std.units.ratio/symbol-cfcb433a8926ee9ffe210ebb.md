# std.units.ratio — ‱

Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Int64/Bool/binary64 or the referenced public typed profile; native checked arithmetic and complete source statement ownership. Int64/Bool/binary64/Unicode scalar values; checked arithmetic; lexical evaluation once

```text
Identity: NSR-DOM-021 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
lexeme: ‱
arity: 1
operand_rule: exact numeric value
result_rule: BasisPoints exact ratio scaled by 1/10000
canonical_ascii: BasisPoints()
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Int64/Bool/binary64 or the referenced public typed profile; native checked arithmetic and complete source statement ownership. Int64/Bool/binary64/Unicode scalar values; checked arithmetic; lexical evaluation once

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Int64/Bool/binary64 or the referenced public typed profile; native checked arithmetic and complete source statement ownership. Int64/Bool/binary64/Unicode scalar values; checked arithmetic; lexical evaluation once Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

OPERATOR_REGISTRY_TYPED_SOURCE_OWNER. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### operator:ratio-e280b1-0-False; expected 23

```nebo
start(){(0‱).q;flow.assert(q == 0‱);23.return;}
```

Oracle: {"capabilities": {"console": "NO_DOCUMENT_OBSERVER", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "filesystem_effects": {}, "independent_builds": 2, "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### operator:wrong-domain-e280b1; expected NEBO_TYPE_MISMATCH

```nebo
(Int.self)invalid(){(true‱).return;}start(){7.invalid().return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-894a93dfb9864d4f1c3add6d](symbol-894a93dfb9864d4f1c3add6d.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/semantic/bindings/binding_vertical.asm — SHA-256 47e3a89c66a2251ca2b8c30eb3faa17078d71a74751d9aafe2ae89f9d23561ce

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
