# public-scientific — shuffle

Explicit SplitMix64 v1 state, no entropy capability; native finite-domain distributions and categorical Float Vector weights; nonnegative Int uniform; shuffle of unique local mutable Int Slice at most 64 lanes; lexical creation/release provenance, separate descriptor/payload frames; sample of Int Vector/local Slice returns canonical List with 0..16 entries; independent seed/value/order oracles and rejected effectful interpolation; no whole-source report

```text
Identity: public:claim:672cbc44e1fd06f50a7411eb (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
shuffle
Explicit SplitMix64 v1 state, no entropy capability; native finite-domain distributions and categorical Float Vector weights; nonnegative Int uniform; shuffle of unique local mutable Int Slice at most 64 lanes; lexical creation/release provenance, separate descriptor/payload frames; sample of Int Vector/local Slice returns canonical List with 0..16 entries; independent seed/value/order oracles and rejected effectful interpolation; no whole-source report
```

## Availability and maturity

STABLE_1_0; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Explicit SplitMix64 v1 state, no entropy capability; native finite-domain distributions and categorical Float Vector weights; nonnegative Int uniform; shuffle of unique local mutable Int Slice at most 64 lanes; lexical creation/release provenance, separate descriptor/payload frames; sample of Int Vector/local Slice returns canonical List with 0..16 entries; independent seed/value/order oracles and rejected effectful interpolation; no whole-source report

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### random:shuffle-return-0; expected 0

```nebo
start(){Random.seed(17).r;Array<Int,4> [17,29,43,71].a.mutable;a.asSlice().s;r.shuffle(s);s.at(0).v0;s.at(1).v1;s.at(2).v2;s.at(3).v3;"${v0}/${v1}/${v2}/${v3}".console();0.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "43/17/29/71", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2\], "process_exit": 0, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "cbb1ea41ae45495e43998b57cfe3d6bcb54132f8bf8ade89edfc0d5d0bb2df8e", "text": {"bytes_hex": "34332f31372f32392f3731"}}

## Rejected examples

### random:shuffle-readonly; expected NEBO_TYPE_MISMATCH

```nebo
start(){Random.seed(17).r;Array<Int,4> [17,29,43,71].a;a.asSlice().s;r.shuffle(s);23.return;}
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

- tests/rf204/G170/random_test.py — SHA-256 a4d3692d30d6947812089d0ad64318a32a6a9279c567ac96481f207daeb95516

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
