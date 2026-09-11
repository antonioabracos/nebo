# builtin.Text — formatter interpolation

Ordinary token/AST expression children; native pure-only effect policy with resolved callee bodies; static G059 nodes and G062 profiles; 64 segments, 16 nested quotes, 4096 source-content bytes; native named-product fields preserve declared types/offsets and source order (8 declarations/8 fields); native-token tooling preserves literals and exposes expressions; rename uses existing G162 receiver-method SymbolIds; privacy remains a separate obligation Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation

```text
Identity: g061-format:formatter interpolation (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
formatter interpolation
Ordinary token/AST expression children; native pure-only effect policy with resolved callee bodies; static G059 nodes and G062 profiles; 64 segments, 16 nested quotes, 4096 source-content bytes; native named-product fields preserve declared types/offsets and source order (8 declarations/8 fields); native-token tooling preserves literals and exposes expressions; rename uses existing G162 receiver-method SymbolIds; privacy remains a separate obligation Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Ordinary token/AST expression children; native pure-only effect policy with resolved callee bodies; static G059 nodes and G062 profiles; 64 segments, 16 nested quotes, 4096 source-content bytes; native named-product fields preserve declared types/offsets and source order (8 declarations/8 fields); native-token tooling preserves literals and exposes expressions; rename uses existing G162 receiver-method SymbolIds; privacy remains a separate obligation Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Ordinary token/AST expression children; native pure-only effect policy with resolved callee bodies; static G059 nodes and G062 profiles; 64 segments, 16 nested quotes, 4096 source-content bytes; native named-product fields preserve declared types/offsets and source order (8 declarations/8 fields); native-token tooling preserves literals and exposes expressions; rename uses existing G162 receiver-method SymbolIds; privacy remains a separate obligation Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

CORRECTED_FORMAT_CONTRACT_ROW. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Negative applicability

No additional source diagnostic is invented for this row. The stated receiver and profile bounds and the associated owner tests define admissibility.

## Executed examples

### interpolation:tooling-format-source; expected 23

```nebo
start(){"Ω  ${17
 +29} end  ".console();23.return;}

```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "Ω  46 end  ", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "publications": 1, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "eb2fe6144586926ab57865f4d41a8e06948bfec62a174d7953fa5a59a96cf855", "text": {"bytes_hex": "cea92020343620656e642020"}}

## Additional observations and limits

```text
[
  {
    "case_id": "interpolation:tooling-format-invalid",
    "category": "tooling"
  }
]
```

## Related entries

[Index](index.md)

- [symbol-744da926f94929d16c738e1a](symbol-744da926f94929d16c738e1a.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/interpolation_test.py — SHA-256 54716aea543d4dd9d1b212acd63e1819d4e6b54b6bef5a597f0b50fab2d9a68a

- tests/rf204/G170/interpolation_tooling_test.py — SHA-256 0523acc9bfe1a8fadaa92ebff5f217c2a8c1b7dcc976b9340268082958ea9965

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
