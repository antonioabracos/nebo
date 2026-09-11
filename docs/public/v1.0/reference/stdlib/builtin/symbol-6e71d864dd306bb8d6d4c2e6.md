# builtin — root

Spelling alias for g009-public:Tree.root; no additional API counted; preserve qualified profile limits; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Int64 payloads; 32 nodes/256 edges; authenticated handle/owner pair; no stale or foreign handle

```text
Identity: claim:79eadfe5d0e112c7b8276900 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
root
Spelling alias for g009-public:Tree.root; no additional API counted; preserve qualified profile limits; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Int64 payloads; 32 nodes/256 edges; authenticated handle/owner pair; no stale or foreign handle
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Spelling alias for g009-public:Tree.root; no additional API counted; preserve qualified profile limits; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Int64 payloads; 32 nodes/256 edges; authenticated handle/owner pair; no stale or foreign handle

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Spelling alias for g009-public:Tree.root; no additional API counted; preserve qualified profile limits; native intrinsic identity is receiver-qualified; no serialized SymbolId or DocRecord is declared by this owner; interface metadata is verified by the separate metadata suite Int64 payloads; 32 nodes/256 edges; authenticated handle/owner pair; no stale or foreign handle Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

REGISTRY_ATOM_TO_QUALIFIED_DECLARATIONS. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### relation:tree-child; expected 71

```nebo
start(){Tree<Int>.new(17).t;t.addChild(t.root(),71).n;n.value().return;}
```

Oracle: {"capabilities": {"console": "NO_DOCUMENT_OBSERVER", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "filesystem_effects": {}, "independent_builds": 2, "process_exit": 71, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### relation:tree-root-arity; expected NEBO_TYPE_MISMATCH

```nebo
start(){Tree<Int>.new(17).t;t.root(17);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-9d8a5564938a4f18e79eb824](symbol-9d8a5564938a4f18e79eb824.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/codegen/collections/x86_64/relational_codegen.inc — SHA-256 4fc920e30696aa75e9c957a6cd8bfb079878d56a5077ed965abafa9eb38156c4

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/graph/relational_public.asm — SHA-256 fe8e1c4de4dfb7159db69fc98e881498d71dec7190a9eebf60262c2a5aa09533

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/relational_test.py — SHA-256 1810f1ccd76da2f50e04c4bc58e86ae3bb6059562a01f01819daa3d1a2080c01
