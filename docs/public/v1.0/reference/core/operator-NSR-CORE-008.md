# : — typed/named separator

Separates names from types or values. It is not the C ternary separator in the canonical language.

```text
Identity: NSR-CORE-008 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: ACTIVE
```

## Syntax or signature

```text
lexeme: :
context: type annotations, named arguments, fields and schemas
fixity: separator/contextual
arity: 2
precedence: STRUCTURAL
associativity: N/A
canonical_ascii: :
operand_rule: name/type or name/value according to context
result_rule: annotation or association
```

## Evaluation and types

compile-time only. Short-circuit: NO. Operand rule: name/type or name/value according to context. Result rule: annotation or association.

## Errors and remediation

context-specific diagnostic; \`=\` is not a named-argument separator. Current native grammar/context only; no implicit activation. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

ACTIVE in core. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Int64/Bool/binary64 or the referenced public typed profile; native checked arithmetic and complete source statement ownership. Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Executed examples

### format:named-29; expected 23

```nebo
start(){"%{nome:s} %{idade:d}".format(idade:29,nome:"Nebo").console();23.return;}
```

Oracle: {"console_text_utf8": "Nebo 29", "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "publications": 1, "runtime_sha256": "24253aa11c0a6b29cceeba77358c8993612e4583acf386028a1da0cb42d43f26"}

## Rejected examples

### format:named-absent; expected NEBO-FORMAT-005

```nebo
start(){"%{other:d}".format(value:17);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-FORMAT-005"}

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

- tests/rf204/G170/format_test.py — SHA-256 f4539de327f15036d30b3184af38af88a729bce118650704c350d30f04820318

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
