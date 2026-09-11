# /name{...} — Slash render directive

Semantic rendering directive; outside a Slash template \`/\` remains division.

```text
Identity: NSR-DOM-079 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: ACTIVE_BOUNDED
```

## Syntax or signature

```text
lexeme: /name{...}
context: inside Slash-enabled Text/RenderPlan templates only
fixity: template directive
arity: 1+
precedence: TEXT_TEMPLATE_GRAMMAR
associativity: N/A
canonical_ascii: RenderPlan directive
operand_rule: registered bounded directive and validated body/options
result_rule: RenderPlan node with plain fallback
```

## Evaluation and types

template order. Short-circuit: NO. Operand rule: registered bounded directive and validated body/options. Result rule: RenderPlan node with plain fallback.

## Errors and remediation

unknown directive policy explicit; anti-Turing limits. Actual typed RenderPlan(Text).render(contextual target) consumes all source statements. The existing native Slash parser and two-pass renderer own 64 finite directives, 4096 input bytes, 256 aggregate tokens, depth 16 and 32 argument bytes. Target output is an owned Text projection; its separate Console publication is observed. Unknown directives and overflowing plans fail closed. Independent G064 grammar/render oracle, actual contents, two live plans and explicit returns replace the old template metadata/seed profile. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

ACTIVE_BOUNDED in std.render.slash. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Actual typed RenderPlan(Text).render(contextual target) consumes all source statements. The existing native Slash parser and two-pass renderer own 64 finite directives, 4096 input bytes, 256 aggregate tokens, depth 16 and 32 argument bytes. Target output is an owned Text projection; its separate Console publication is observed. Unknown directives and overflowing plans fail closed. Independent G064 grammar/render oracle, actual contents, two live plans and explicit returns replace the old template metadata/seed profile. Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Executed examples

### slash:domain-unknown; expected 175

```nebo
start(){RenderPlan("/missing{x}").render(.plain()).console();23.return;}
```

Oracle: {"independent_builds": 2, "process_exit": 175, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### slash:status-type; expected NEBO_ENTRYPOINT_INVALID_SIGNATURE

```nebo
start(){RenderPlan("a").return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_ENTRYPOINT_INVALID_SIGNATURE"}

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

- tests/rf204/G170/slash_test.py — SHA-256 f25f3e8878b8e7a0281d721f375c25eb5653cccfc146868ec7db4d447400b1c4

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
