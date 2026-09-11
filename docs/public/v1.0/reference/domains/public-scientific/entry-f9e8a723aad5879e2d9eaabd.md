# public-scientific — ⊗

Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Exact immutable Int Vector aggregate grammar, extent 1..4; matrix Int/Complex profile at most four logical cells; vector observers sum, checked rational inverse numerator/denominator, exact integer norm; symbolic/named parity; all source tokens consumed by the canonical current profile, without adjacent statements. Typed infix statement profile additionally supports Int extents 1..64 (cross/parallel exactly 3), tensor result at most 64 lanes; native checked kernels, distinct owned results, ordered operands and explicit program return.

```text
Identity: public:NSR-DOM-039 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
⊗
Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Exact immutable Int Vector aggregate grammar, extent 1..4; matrix Int/Complex profile at most four logical cells; vector observers sum, checked rational inverse numerator/denominator, exact integer norm; symbolic/named parity; all source tokens consumed by the canonical current profile, without adjacent statements. Typed infix statement profile additionally supports Int extents 1..64 (cross/parallel exactly 3), tensor result at most 64 lanes; native checked kernels, distinct owned results, ordered operands and explicit program return.
```

## Availability and maturity

STABLE_1_0; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Exact Registry token and real Program statements; independent value/document/exit oracles, changed operands, associated negatives; Exact immutable Int Vector aggregate grammar, extent 1..4; matrix Int/Complex profile at most four logical cells; vector observers sum, checked rational inverse numerator/denominator, exact integer norm; symbolic/named parity; all source tokens consumed by the canonical current profile, without adjacent statements. Typed infix statement profile additionally supports Int extents 1..64 (cross/parallel exactly 3), tensor result at most 64 lanes; native checked kernels, distinct owned results, ordered operands and explicit program return.

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### boundedoperator:dom-039-named-0; expected 171

```nebo
start(){Vector<Int,3> [2,3,4].a;Vector<Int,3> [5,6,8].b;a.tensorProduct(b).sum();}
```

Oracle: {"capabilities": {"console": "NO_DOCUMENT_OBSERVER", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "filesystem_effects": {}, "independent_builds": 2, "process_exit": 171, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

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

- docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv — SHA-256 b7e5694ceadf30ccffb4077c994fe230d2a10201b64dc6e9e218bdcf4b157f14

- tests/rf204/G170/bounded_operator_test.py — SHA-256 a756e75fb059c5f5837b1ab76490c31b8e92762f0400cad0d2545ff0532beaf5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
