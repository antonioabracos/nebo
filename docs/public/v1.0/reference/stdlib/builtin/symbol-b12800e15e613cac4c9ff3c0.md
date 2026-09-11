# builtin — groupBy

Spelling alias for g010-public:Table.groupBy,g010-public:Table.groupBy.next,g010-public:Table.groupBy.sink; no additional API counted; preserve qualified profile limits; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Typed nullable integer rows/columns/tables/datasets/streams; finite schema, rows and stages; lazy callbacks once

```text
Identity: claim:2e1c93122fc13d6d34df1b59 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
groupBy
Spelling alias for g010-public:Table.groupBy,g010-public:Table.groupBy.next,g010-public:Table.groupBy.sink; no additional API counted; preserve qualified profile limits; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Typed nullable integer rows/columns/tables/datasets/streams; finite schema, rows and stages; lazy callbacks once
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Spelling alias for g010-public:Table.groupBy,g010-public:Table.groupBy.next,g010-public:Table.groupBy.sink; no additional API counted; preserve qualified profile limits; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Typed nullable integer rows/columns/tables/datasets/streams; finite schema, rows and stages; lazy callbacks once

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Spelling alias for g010-public:Table.groupBy,g010-public:Table.groupBy.next,g010-public:Table.groupBy.sink; no additional API counted; preserve qualified profile limits; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Typed nullable integer rows/columns/tables/datasets/streams; finite schema, rows and stages; lazy callbacks once Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

REGISTRY_ATOM_TO_QUALIFIED_DECLARATIONS. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### data:group-normal-cleanup; expected 23

```nebo
start(){Table.fromColumns([Tuple.of("key",Column<Int>.from([29,17,29])),Tuple.of("value",Column<Int>.from([71,83,97]))]).t;0.i.mutable;while(i<3){t.groupBy(["key"]).g;g.length().console();i+=1;}23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "222", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4, 4, 4\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "04047b3d79682628f96d16b4f9e55a0b8b07bf51788e51a2fb1128616b094cda", "text": {"bytes_hex": "323232"}}

## Rejected examples

### data:group-method-arity; expected NEBO_TYPE_MISMATCH

```nebo
start(){Table.fromColumns([Tuple.of("key",Column<Int>.from([17]))]).t;t.groupBy();23.return;}
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
