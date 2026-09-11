# builtin.ScanPlan — code

Contextual alias for g170-scan:code; public typed source proof replaces the historical seed/probe evidence. Preserve the qualified row bounds; no separate global option or live capability is claimed. Synthetic mock/stdin replay; typed bounded ScanPlan; redaction; no real secret or live device

```text
Identity: claim:9c7d133565d37ffa1f0d008c (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
code
Contextual alias for g170-scan:code; public typed source proof replaces the historical seed/probe evidence. Preserve the qualified row bounds; no separate global option or live capability is claimed. Synthetic mock/stdin replay; typed bounded ScanPlan; redaction; no real secret or live device
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Contextual alias for g170-scan:code; public typed source proof replaces the historical seed/probe evidence. Preserve the qualified row bounds; no separate global option or live capability is claimed. Synthetic mock/stdin replay; typed bounded ScanPlan; redaction; no real secret or live device

## Effects, capabilities and sandbox

input,console; SYNTHETIC_INPUT_AND_RETAINED_CONSOLE. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Contextual alias for g170-scan:code; public typed source proof replaces the historical seed/probe evidence. Preserve the qualified row bounds; no separate global option or live capability is claimed. Synthetic mock/stdin replay; typed bounded ScanPlan; redaction; no real secret or live device Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

REGISTRY_ATOM_TO_CONTEXTUAL_TYPED_SOURCE. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### scan:multiline-code-replay; expected 23

```nebo
start(){"Input".scan(.code("nebo"),.replay("answers.txt")).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "start(){\n23.return;\n}", "filesystem_effects": {}, "independent_builds": 2, "inputs": {"answers.txt": {"bytes_hex": "737461727428297b0a32332e72657475726e3b0a7d0a"}}, "kinds": \[2, 3, 2, 3, 2\], "process_exit": 23, "publications": 1, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "455592bf762ba97bc24a5670ec6ee97aed55f310385edbe394ccea0802c3ccc6", "text": {"bytes_hex": "737461727428297b0a32332e72657475726e3b0a7d"}}

## Rejected examples

### scan:multiline-type-code; expected NEBO_TYPE_MISMATCH

```nebo
start(){"Input".scan(.code(17));23.return;}
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
