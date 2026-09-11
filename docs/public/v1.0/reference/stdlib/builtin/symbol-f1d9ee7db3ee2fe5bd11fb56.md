# builtin — Table.join

Single shared Int key; native kind 1 inner/2 left; &lt;=32 rows/8 output fields; key emitted once, distinct non-key names; left-then-right order; missing never matches; native registry identity and runtime profile are explicit; serialized interface metadata is verified by the separate metadata suite Typed nullable integer rows/columns/tables/datasets/streams; finite schema, rows and stages; lazy callbacks once

```text
Identity: g010-public:Table.join (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
Table.join
Single shared Int key; native kind 1 inner/2 left; <=32 rows/8 output fields; key emitted once, distinct non-key names; left-then-right order; missing never matches; native registry identity and runtime profile are explicit; serialized interface metadata is verified by the separate metadata suite Typed nullable integer rows/columns/tables/datasets/streams; finite schema, rows and stages; lazy callbacks once
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Single shared Int key; native kind 1 inner/2 left; &lt;=32 rows/8 output fields; key emitted once, distinct non-key names; left-then-right order; missing never matches; native registry identity and runtime profile are explicit; serialized interface metadata is verified by the separate metadata suite Typed nullable integer rows/columns/tables/datasets/streams; finite schema, rows and stages; lazy callbacks once

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Single shared Int key; native kind 1 inner/2 left; &lt;=32 rows/8 output fields; key emitted once, distinct non-key names; left-then-right order; missing never matches; native registry identity and runtime profile are explicit; serialized interface metadata is verified by the separate metadata suite Typed nullable integer rows/columns/tables/datasets/streams; finite schema, rows and stages; lazy callbacks once Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

CORRECTED_PUBLIC_CONTRACT_TYPED_NATIVE_OWNER. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### data:join-source-preserved; expected 2

```nebo
start(){Table.fromColumns([Tuple.of("key",Column<Int>.from([17,29])),Tuple.of("age",Column<Int>.from([71,83]))]).left;Table.fromColumns([Tuple.of("key",Column<Int>.from([17])),Tuple.of("score",Column<Int>.from([103]))]).right;left.join(right,["key"],2).out;left.rowCount().console();right.rowCount().console();out.rowCount().return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "21", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4, 4\], "process_exit": 2, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "96ad61121db0a5a5fb7f4350ecebd3c53eddab057cd329caede5750005acf96d", "text": {"bytes_hex": "3231"}}

## Rejected examples

### data:join-keys-type; expected NEBO_TYPE_MISMATCH

```nebo
start(){Table.fromColumns([Tuple.of("key",Column<Int>.from([17]))]).a;Table.fromColumns([Tuple.of("key",Column<Int>.from([17]))]).b;a.join(b,[17],1);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-9d8a5564938a4f18e79eb824](symbol-9d8a5564938a4f18e79eb824.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/data_test.py — SHA-256 f1a7df13b11c4ec4c931662edeac8d25f3cbb8822b8edcf9d99b32daa451429b

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
