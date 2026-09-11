# std.calculus — ∫

Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Explicit finite samples, dimensions, method, tolerance/step and budget in the current checked calculus grammar; exact rational/integer observations; no implicit integration domain, numeric truncation, live solver or hidden callback. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value

```text
Identity: NSR-DOM-049 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
lexeme: ∫
arity: 1+
operand_rule: integrable callable/expression, explicit variable/domain, method and tolerance
result_rule: IntegralResult<T>
canonical_ascii: integrate()
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Explicit finite samples, dimensions, method, tolerance/step and budget in the current checked calculus grammar; exact rational/integer observations; no implicit integration domain, numeric truncation, live solver or hidden callback. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Explicit finite samples, dimensions, method, tolerance/step and budget in the current checked calculus grammar; exact rational/integer observations; no implicit integration domain, numeric truncation, live solver or hidden callback. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

OPERATOR_REGISTRY_TYPED_SOURCE_OWNER. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### boundedoperator:dom-049-e288ab-0; expected 2

```nebo
start(){∫(x,0,2,trapezoid,1,16,[0,1,2]).value();}
```

Oracle: {"capabilities": {"console": "NO_DOCUMENT_OBSERVER", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "filesystem_effects": {}, "independent_builds": 2, "process_exit": 2, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### boundedoperator:dom-049-negative; expected NEBO_TYPE_UNSUPPORTED_OPERATOR

```nebo
// Numeric integration does not infer or silently repair a zero tolerance.
start() { ∫(x, 0, 1, trapezoid, 0, 8, [1, 2]).value(); }

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_UNSUPPORTED_OPERATOR"}

## Related entries

[Index](index.md)

- [symbol-eb171ac7a2bbf931bae9de36](symbol-eb171ac7a2bbf931bae9de36.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/bounded_operator_test.py — SHA-256 a756e75fb059c5f5837b1ab76490c31b8e92762f0400cad0d2545ff0532beaf5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
