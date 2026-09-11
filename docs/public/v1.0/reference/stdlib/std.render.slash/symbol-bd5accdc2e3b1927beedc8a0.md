# std.render.slash — /name{...}

Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Actual typed RenderPlan(Text).render(contextual target) consumes all source statements. The existing native Slash parser and two-pass renderer own 64 finite directives, 4096 input bytes, 256 aggregate tokens, depth 16 and 32 argument bytes. Target output is an owned Text projection; its separate Console publication is observed. Unknown directives and overflowing plans fail closed. Independent G064 grammar/render oracle, actual contents, two live plans and explicit returns replace the old template metadata/seed profile. Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation

```text
Identity: NSR-DOM-079 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
lexeme: /name{...}
arity: 1+
operand_rule: registered bounded directive and validated body/options
result_rule: RenderPlan node with plain fallback
canonical_ascii: RenderPlan directive
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Actual typed RenderPlan(Text).render(contextual target) consumes all source statements. The existing native Slash parser and two-pass renderer own 64 finite directives, 4096 input bytes, 256 aggregate tokens, depth 16 and 32 argument bytes. Target output is an owned Text projection; its separate Console publication is observed. Unknown directives and overflowing plans fail closed. Independent G064 grammar/render oracle, actual contents, two live plans and explicit returns replace the old template metadata/seed profile. Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Actual typed RenderPlan(Text).render(contextual target) consumes all source statements. The existing native Slash parser and two-pass renderer own 64 finite directives, 4096 input bytes, 256 aggregate tokens, depth 16 and 32 argument bytes. Target output is an owned Text projection; its separate Console publication is observed. Unknown directives and overflowing plans fail closed. Independent G064 grammar/render oracle, actual contents, two live plans and explicit returns replace the old template metadata/seed profile. Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

OPERATOR_REGISTRY_TYPED_SOURCE_OWNER. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### slash:directive-bold; expected 23

```nebo
start(){RenderPlan("/bold{Nebo17}").render(.plain()).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "Nebo17", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "publications": 1, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "f3f817e303ae373a3fcce7b90c9f191803d7560a3fe7824da79b2e0b3cb68b79", "text": {"bytes_hex": "4e65626f3137"}}

## Rejected examples

### slash:status-type; expected NEBO_ENTRYPOINT_INVALID_SIGNATURE

```nebo
start(){RenderPlan("a").return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_ENTRYPOINT_INVALID_SIGNATURE"}

## Related entries

[Index](index.md)

- [symbol-2857ca62d501577b238a68b4](symbol-2857ca62d501577b238a68b4.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/slash_test.py — SHA-256 f25f3e8878b8e7a0281d721f375c25eb5653cccfc146868ec7db4d447400b1c4

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
