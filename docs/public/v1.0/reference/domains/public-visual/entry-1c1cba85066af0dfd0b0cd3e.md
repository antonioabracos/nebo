# public-visual — console

Actual edition-owned prelude SymbolId and unique stdlib owner; CLI metadata checked against the local .ni interface and independent FNV identity. Runtime profile is the cited source case family. Iterator/IntoIterator dispatch is bounded Range iteration, not a standalone cursor constructor or arbitrary iterator implementation. Ord reuses the existing comparable capability, with explicit Bool rejection. Native intrinsic profiles are not promoted to arbitrary generic APIs.

```text
Identity: public:claim:992d32bcce649fc5aa92fd76 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
console
Actual edition-owned prelude SymbolId and unique stdlib owner; CLI metadata checked against the local .ni interface and independent FNV identity. Runtime profile is the cited source case family. Iterator/IntoIterator dispatch is bounded Range iteration, not a standalone cursor constructor or arbitrary iterator implementation. Ord reuses the existing comparable capability, with explicit Bool rejection. Native intrinsic profiles are not promoted to arbitrary generic APIs.
```

## Availability and maturity

STABLE_1_0; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Actual edition-owned prelude SymbolId and unique stdlib owner; CLI metadata checked against the local .ni interface and independent FNV identity. Runtime profile is the cited source case family. Iterator/IntoIterator dispatch is bounded Range iteration, not a standalone cursor constructor or arbitrary iterator implementation. Ord reuses the existing comparable capability, with explicit Bool rejection. Native intrinsic profiles are not promoted to arbitrary generic APIs.

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### console:publish-17; expected 23

```nebo
start(){(17).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_state_trace": true, "console_text_utf8": "17", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4\], "observation": {"native_oracle": "console_public_test.compare"}, "process_exit": 23, "publications": 1, "runtime_determinism": "DOMAIN_INVARIANTS", "runtime_sha256": "ef63802d6adb274672ff60210fb3e604b8b8a8cb20f791d1a031c8b9da9add38", "text": {"bytes_hex": "3137"}}

## Rejected examples

### console:bare-color; expected NEBO_TYPE_MISMATCH

```nebo
start(){"seed".console(Color.rgb(17,29,53));23.return;}
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

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- tests/rf204/G170/console_public_test.py — SHA-256 4ff1b67ea212ce82443057d944c9993e64ad919fe90faadb19f0cb6014f4cff5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
