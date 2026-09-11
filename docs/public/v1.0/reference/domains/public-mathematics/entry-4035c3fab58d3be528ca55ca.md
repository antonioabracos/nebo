# public-mathematics — log

Literal Int64/binary64 operands; at most 128 complete statements; independent arithmetic trace and return matrix

```text
Identity: public:claim:ee65c8536fe60039f4a5f212 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
log
Literal Int64/binary64 operands; at most 128 complete statements; independent arithmetic trace and return matrix
```

## Availability and maturity

STABLE_1_0; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Literal Int64/binary64 operands; at most 128 complete statements; independent arithmetic trace and return matrix

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### math:log; expected 29

```nebo
start(){std.math.log(7.0);29.return;}
```

Oracle: {"binary64_tolerance": {"absolute": 1e-12, "relative": 1e-12}, "capabilities": {"console": "NO_DOCUMENT_OBSERVER", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "filesystem_effects": {}, "independent_builds": 2, "independent_math_values": \[\[13, 2, 1.9459101490553132\]\], "math_trace_sha256": "7e0e691062ff9f6dffc1286b3e0acf624c957d382513fabc75f11c152d3caf33", "observed_math_calls": 1, "process_exit": 29, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### math:math-text-return; expected NEBO_TYPE_MISMATCH

```nebo
// Scalar owners expose checked integer domains and stable binary64 magnitude.
start() {
    141;
    std.math.max(17, 29);
    std.math.min(17, 29);
    std.math.abs(-37);
    std.math.clamp(41, 7, 23);
    std.math.sqrt(9.0);
    std.math.pow(2.0, 5.0);
    std.math.hypot(5.0, 12.0);
    "bad".return;
}

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

- tests/rf204/G170/math_return_test.py — SHA-256 80e2b9b0eb7f676a90c810e50ac8451ed7fe7145012a7e085715f85997e26b81

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
