# ${...} — Text interpolation

Syntax B from RF84; lowers to the same FormatPlan as \`.format(...)\`.

```text
Identity: NSR-DOM-077 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: ACTIVE_BOUNDED
```

## Syntax or signature

```text
lexeme: ${...}
context: inside interpolated Text literals only
fixity: embedded expression
arity: 1
precedence: TEXT_TEMPLATE_GRAMMAR
associativity: N/A
canonical_ascii: FormatPlan interpolation
operand_rule: pure expression accepted by the interpolation profile
result_rule: Text segment/FormatPlan value
```

## Evaluation and types

left-to-right exactly once. Short-circuit: NO. Operand rule: pure expression accepted by the interpolation profile. Result rule: Text segment/FormatPlan value.

## Errors and remediation

compile-time type/format diagnostics. Current native grammar/context only; no implicit activation. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

ACTIVE_BOUNDED in std.text.format. Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Int64/Bool/binary64 or the referenced public typed profile; native checked arithmetic and complete source statement ownership. Checked format/interpolation profile; 64 segments; finite text/output budgets; pure interpolation The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Executed examples

### interpolation:tooling-format-source; expected 23

```nebo
start(){"Ω  ${17
 +29} end  ".console();23.return;}

```

Oracle: {"console_text_utf8": "Ω  46 end  ", "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "publications": 1, "runtime_sha256": "eb2fe6144586926ab57865f4d41a8e06948bfec62a174d7953fa5a59a96cf855"}

## Rejected examples

### interpolation:effect-console; expected NEBO_INTERPOLATION_EFFECT_FORBIDDEN

```nebo
start(){"${17.console()}";23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_INTERPOLATION_EFFECT_FORBIDDEN"}

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

- tests/rf204/G170/interpolation_test.py — SHA-256 54716aea543d4dd9d1b212acd63e1819d4e6b54b6bef5a597f0b50fab2d9a68a

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
