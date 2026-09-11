# builtin — Deque.pushBack

Int64 elements; 16 live values; native List/Stack/ring storage and algorithms; typed callback bridges; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Typed sequential storage, views and checked indices; ownership and capacity follow exact declaration

```text
Identity: g007-public:Deque.pushBack (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
Deque.pushBack
Int64 elements; 16 live values; native List/Stack/ring storage and algorithms; typed callback bridges; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Typed sequential storage, views and checked indices; ownership and capacity follow exact declaration
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Int64 elements; 16 live values; native List/Stack/ring storage and algorithms; typed callback bridges; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Typed sequential storage, views and checked indices; ownership and capacity follow exact declaration

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Int64 elements; 16 live values; native List/Stack/ring storage and algorithms; typed callback bridges; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Typed sequential storage, views and checked indices; ownership and capacity follow exact declaration Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

CORRECTED_PUBLIC_CONTRACT_TYPED_NATIVE_OWNER. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### sequence:deque-ends; expected 23

```nebo
start(){Deque<Int>.new().d;d.pushBack(29);d.pushFront(17);d.pushBack(71);d.popBack().console();d.popFront().console();d.popFront().console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "711729", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4, 4, 4\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "76b8704d0b42c8b7148e2ef21cf3210f86ad3dd593b5e44b2f6458271c10bd63", "text": {"bytes_hex": "373131373239"}}

## Rejected examples

### sequence:Deque-wrong-value; expected NEBO_TYPE_MISMATCH

```nebo
start(){Deque<Int>.new().a;a.pushBack(true);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-9d8a5564938a4f18e79eb824](symbol-9d8a5564938a4f18e79eb824.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/codegen/collections/x86_64/sequential_codegen.inc — SHA-256 de217a65f85ffcbb4e12dbb86d94774241c1807c893b794d85c689699fb87f78

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/collections/sequential_public.asm — SHA-256 11d700cabf4bb549a079bad0049ebacf087b7b7d16afb072095aea24e7ef9580

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/sequential_test.py — SHA-256 5036cff3501816a4639df0dbe6bd0e7f60a61025324cf160aa96b3121b5909ea
