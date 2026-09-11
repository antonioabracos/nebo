# public-visual — ScanPlan.multiline

Real contextual option AST children, lexical operands and native ScanPlan owners. Text UTF-8 &lt;=4096 bytes; Int64; Bool true/false; Char one-byte profile; 1..32 choices; finite retries &lt;=8; readonly relative replay file &lt;=4096 bytes/path&lt;=256; typed Option&lt;Int&gt;/Result&lt;T,ScanError&gt;; headless Console metadata and pointer-free native events. Public secret events hide input bytes/length/digest. No live backend claim. Multiline/paragraph/block/Markdown/code/JSON/raw modes use native G078/G080 owners with at most 256 lines; finite Console enum choices are not nominal enum reflection; multiSelect exposes the native unique 32-bit mask; confirmSecret consumes a second input; forgetAfterUse zeroizes consumed private bytes and preserves the owned result. At most 32 total options. SymbolId/DocRecord reconciliation stays in F01.

```text
Identity: public:g170-scan:multiline (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
ScanPlan.multiline
Real contextual option AST children, lexical operands and native ScanPlan owners. Text UTF-8 <=4096 bytes; Int64; Bool true/false; Char one-byte profile; 1..32 choices; finite retries <=8; readonly relative replay file <=4096 bytes/path<=256; typed Option<Int>/Result<T,ScanError>; headless Console metadata and pointer-free native events. Public secret events hide input bytes/length/digest. No live backend claim. Multiline/paragraph/block/Markdown/code/JSON/raw modes use native G078/G080 owners with at most 256 lines; finite Console enum choices are not nominal enum reflection; multiSelect exposes the native unique 32-bit mask; confirmSecret consumes a second input; forgetAfterUse zeroizes consumed private bytes and preserves the owned result. At most 32 total options. SymbolId/DocRecord reconciliation stays in F01.
```

## Availability and maturity

STABLE_1_0; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Real contextual option AST children, lexical operands and native ScanPlan owners. Text UTF-8 &lt;=4096 bytes; Int64; Bool true/false; Char one-byte profile; 1..32 choices; finite retries &lt;=8; readonly relative replay file &lt;=4096 bytes/path&lt;=256; typed Option&lt;Int&gt;/Result&lt;T,ScanError&gt;; headless Console metadata and pointer-free native events. Public secret events hide input bytes/length/digest. No live backend claim. Multiline/paragraph/block/Markdown/code/JSON/raw modes use native G078/G080 owners with at most 256 lines; finite Console enum choices are not nominal enum reflection; multiSelect exposes the native unique 32-bit mask; confirmSecret consumes a second input; forgetAfterUse zeroizes consumed private bytes and preserves the owned result. At most 32 total options. SymbolId/DocRecord reconciliation stays in F01.

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### scan:multiline-multiline-stdin; expected 23

```nebo
start(){"Input".scan(.multiline()).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "first\nsecond", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2, 3, 2\], "process_exit": 23, "prompt": {"bytes_hex": "496e707574"}, "publications": 1, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "5ef819560dbae38fe8a89317636f538888b93b847bdbe25024f090f53cf0b084", "stdin": {"bytes_hex": "66697273740a7365636f6e640a"}, "text": {"bytes_hex": "66697273740a7365636f6e64"}}

## Rejected examples

### scan:multiline-type-conflict; expected NEBO_TYPE_MISMATCH

```nebo
start(){"Input".scan(.int(),.multiline());23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Additional observations and limits

```text
[
  {
    "classification": {
      "capability": "NONE",
      "core": "YES",
      "evidence_level": "FROZEN_PUBLIC_SOURCE",
      "external_gate": "NONE",
      "hardware_claim": "NO",
      "import_grants_capability": "NO",
      "legal": "RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE",
      "security_assurance": "NO",
      "target": "x86_64-systemv-elf-linux",
      "tier": "STABLE_1_0"
    }
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/scan_public_test.py — SHA-256 e487ed7a7709494b21d44b475371945fa537edb1ce2850f8719f76381b3e7e35

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
