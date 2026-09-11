# std.math.reduce — ∏

Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Finite immutable Array&lt;Int,N&gt; domain; canonical checked constant fold in source order; empty identities 0/1; constant overflow is rejected with NEBO_TYPE_CONSTANT_OVERFLOW; later publication and explicit return remain in the shared Program. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value

```text
Identity: NSR-DOM-009 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
lexeme: ∏
arity: 1+
operand_rule: finite iterable plus multiplicative expression
result_rule: type-specific product or reduction report
canonical_ascii: product()
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Finite immutable Array&lt;Int,N&gt; domain; canonical checked constant fold in source order; empty identities 0/1; constant overflow is rejected with NEBO_TYPE_CONSTANT_OVERFLOW; later publication and explicit return remain in the shared Program. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Finite immutable Array&lt;Int,N&gt; domain; canonical checked constant fold in source order; empty identities 0/1; constant overflow is rejected with NEBO_TYPE_CONSTANT_OVERFLOW; later publication and explicit return remain in the shared Program. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

OPERATOR_REGISTRY_TYPED_SOURCE_OWNER. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### operator:reduce-e2888f-\[\]; expected 23

```nebo
start(){Array<Int,0> [].values;(∏values).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "1", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "5045fd7401798a3f5e5ff142ddaf301ef631f92a5499c4029fe3dd26e251335c", "text": {"bytes_hex": "31"}}

## Rejected examples

### operator:wrong-domain-e2888f; expected NEBO_TYPE_MISMATCH

```nebo
(Int.self)invalid(){(∏17).return;}start(){7.invalid().return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-60669ebab2e6b2b8b9a3d412](symbol-60669ebab2e6b2b8b9a3d412.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
