# builtin.ScanPlan — confirmSecret

Contextual alias for g170-scan:confirmSecret; public typed source proof replaces the historical seed/probe evidence. Preserve the qualified row bounds; no separate global option or live capability is claimed. Synthetic mock/stdin replay; typed bounded ScanPlan; redaction; no real secret or live device

```text
Identity: claim:e373f34ea6d115dc9edf77b3 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
confirmSecret
Contextual alias for g170-scan:confirmSecret; public typed source proof replaces the historical seed/probe evidence. Preserve the qualified row bounds; no separate global option or live capability is claimed. Synthetic mock/stdin replay; typed bounded ScanPlan; redaction; no real secret or live device
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Contextual alias for g170-scan:confirmSecret; public typed source proof replaces the historical seed/probe evidence. Preserve the qualified row bounds; no separate global option or live capability is claimed. Synthetic mock/stdin replay; typed bounded ScanPlan; redaction; no real secret or live device

## Effects, capabilities and sandbox

input,console; SYNTHETIC_INPUT_AND_RETAINED_CONSOLE. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Contextual alias for g170-scan:confirmSecret; public typed source proof replaces the historical seed/probe evidence. Preserve the qualified row bounds; no separate global option or live capability is claimed. Synthetic mock/stdin replay; typed bounded ScanPlan; redaction; no real secret or live device Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

REGISTRY_ATOM_TO_CONTEXTUAL_TYPED_SOURCE. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### scan:confirm-trace-Different9!; expected 23

```nebo
start(){"Input".scan(.text(),.console(),.secret(),.confirmSecret(),.result(),.replay("answers.txt")).isOk().console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "false", "filesystem_effects": {}, "independent_builds": 2, "inputs": {"answers.txt": {"bytes_hex": "53796e74686574696337210a446966666572656e7439210a"}}, "kinds": \[5\], "observation": {"native_oracle": "scan_public_test.observe"}, "process_exit": 23, "runtime_determinism": "DOMAIN_INVARIANTS", "runtime_sha256": "e037c0a6b01d582f84c9bc774e8453347665f26c861581f1b6c095bc2730e07d", "scan_trace": true, "text": {"bytes_hex": "66616c7365"}}

## Rejected examples

### scan:security-arity-confirmSecret; expected NEBO_TYPE_MISMATCH

```nebo
start(){"Input".scan(.text(),.secret(),.confirmSecret(17));23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-d0130d0cb21b273482d5c4cf](symbol-d0130d0cb21b273482d5c4cf.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/scan_public_test.py — SHA-256 e487ed7a7709494b21d44b475371945fa537edb1ce2850f8719f76381b3e7e35

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
