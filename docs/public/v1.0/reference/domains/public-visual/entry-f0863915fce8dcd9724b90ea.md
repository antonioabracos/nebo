# public-visual — Color.hex

Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table&lt;Int&gt; 32x8, Tree&lt;Int&gt; 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01.

```text
Identity: public:g170-console:Color.hex (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
Color.hex
Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table<Int> 32x8, Tree<Int> 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01.
```

## Availability and maturity

STABLE_1_0; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table&lt;Int&gt; 32x8, Tree&lt;Int&gt; 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01.

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### console:color-sugar-literal-(17_29_53_71); expected 23

```nebo
start(){Color.hex("#111D3547").c;c.toHex().console();c.toHexWithAlpha().console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_state_trace": true, "console_text_utf8": "#111D35#111D3547", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2, 2\], "observation": {"native_oracle": "console_public_test.compare"}, "process_exit": 23, "publications": 2, "runtime_determinism": "DOMAIN_INVARIANTS", "runtime_sha256": "655ec8d953bf5468f1a4504a4f00b2e88efa5da3c0159816eabbf75b3076628e", "text": {"bytes_hex": "23313131443335233131314433353437"}}

## Rejected examples

### console:color-hex-arity; expected NEBO_TYPE_MISMATCH

```nebo
start(){Color.hex("#12345");23.return;}
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
