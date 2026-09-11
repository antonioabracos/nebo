# xor — typed XOR

Canonical XOR spelling. Existing \`bitXor()\` remains an exact method form.

```text
Identity: NSR-CORE-023 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: ACTIVE
```

## Syntax or signature

```text
lexeme: xor
context: Boolean, Int or Bytes expression
fixity: infix keyword
arity: 2
precedence: P100_XOR
associativity: left
canonical_ascii: xor
operand_rule: Bool/Bool, Int/Int or equal-length Bytes/Bytes
result_rule: Bool, Int or Bytes matching the operand domain
```

## Evaluation and types

left then right exactly once. Short-circuit: NO. Operand rule: Bool/Bool, Int/Int or equal-length Bytes/Bytes. Result rule: Bool, Int or Bytes matching the operand domain.

## Errors and remediation

type/length mismatch rejected; no padding or truncation. Equal Int/Bool/Bytes operands; immutable Bytes XOR requires equal lengths at most 4096; fromByte takes one Int and fromValues four Ints in 0..255; private initialized storage; ordered effects and two live outputs. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

ACTIVE in core.logic_bits. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Equal Int/Bool/Bytes operands; immutable Bytes XOR requires equal lengths at most 4096; fromByte takes one Int and fromValues four Ints in 0..255; private initialized storage; ordered effects and two live outputs. Int64/Bool/binary64/Unicode scalar values; checked arithmetic; lexical evaluation once The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Executed examples

### operator:bytes-xor-empty; expected 23

```nebo
start(){(Bytes.empty() xor Bytes.empty()).byteLength().console();23.return;}
```

Oracle: {"console_text_utf8": "0", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "c88c7d22bff223346890bdb5b122a89860b3aced684fcdafc6675d64140f1f66"}

## Rejected examples

### operator:bytes-xor-mixed; expected NEBO_TYPE_MISMATCH

```nebo
(Int.self)invalid(){Bytes.fromByte(17) xor 29;23.return;}start(){7.invalid().return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

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
