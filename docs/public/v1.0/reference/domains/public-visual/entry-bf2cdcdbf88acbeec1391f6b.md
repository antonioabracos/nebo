# public-visual — Color(Int,Int,Int)

Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table&lt;Int&gt; 32x8, Tree&lt;Int&gt; 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01.

```text
Identity: public:g170-console:Color(Int,Int,Int) (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
Color(Int,Int,Int)
Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table<Int> 32x8, Tree<Int> 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01.
```

## Availability and maturity

STABLE_1_0; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table&lt;Int&gt; 32x8, Tree&lt;Int&gt; 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01.

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### console:color-implicit-standalone; expected 0

```nebo
start(){Color(17,29,53);}
```

Oracle: {"capabilities": {"console": "NO_DOCUMENT_OBSERVER", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "filesystem_effects": {}, "independent_builds": 2, "process_exit": 0, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### console:color-sugar-arity; expected NEBO_TYPE_MISMATCH

```nebo
start(){Color(17,29);23.return;}
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

- tests/rf204/G170/console_public_test.py — SHA-256 4ff1b67ea212ce82443057d944c9993e64ad919fe90faadb19f0cb6014f4cff5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
