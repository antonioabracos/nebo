# std.math.constants — π

Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Int64/Bool/binary64 or the referenced public typed profile; native checked arithmetic and complete source statement ownership. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value

```text
Identity: NSR-DOM-006 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
lexeme: π
arity: 0
operand_rule: context supporting the selected precision
result_rule: typed constant
canonical_ascii: PI
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Int64/Bool/binary64 or the referenced public typed profile; native checked arithmetic and complete source statement ownership. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Int64/Bool/binary64 or the referenced public typed profile; native checked arithmetic and complete source statement ownership. Native checked scalar/vector mathematics; independent numeric oracle; explicit process return separate from intermediate value Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

OPERATOR_REGISTRY_TYPED_SOURCE_OWNER. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### operator:constant-pi-7; expected 7

```nebo
start(){π.v;"%.6f".format(v).console();7.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "3.141593", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2\], "process_exit": 7, "publications": 1, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "17edec55dabd45678dfbd31547db2e5a3dc96821773501b8f4a27dce0cc3d87c", "text": {"bytes_hex": "332e313431353933"}}

## Rejected examples

### operator:wrong-domain-cf80; expected NEBO_TYPE_MISMATCH

```nebo
(Int.self)invalid(){(π + true).return;}start(){7.invalid().return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-44243ba7fd68ec103565a350](symbol-44243ba7fd68ec103565a350.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
