# public-network-boundary — TcpStream

Network access explicitly forbidden in this mission; no socket or external service is opened

```text
Identity: public:claim:c1e8c36540cf3bee9f79998e (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: TARGET_GATED
```

## Syntax or signature

```text
TcpStream
Network access explicitly forbidden in this mission; no socket or external service is opened
```

## Unavailable execution

This row documents a boundary or reserved identity. No executable native implementation, display, device or network access is promised. The quoted classification is retained.

## External gate

NETWORK_NOT_AUTHORIZED. This gate is not satisfied by documentation or by local functional assertions. The exact target/capability requirement remains necessary; no external execution was performed here.

## Availability and maturity

TARGET_GATED; evidence FROZEN_PROFILE_BOUNDARY. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Network access explicitly forbidden in this mission; no socket or external service is opened

## Privacy, dependencies and authority

Capability: NETWORK. Gate: NETWORK_NOT_AUTHORIZED. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Additional observations and limits

```text
[
  {
    "classification": {
      "capability": "NETWORK",
      "core": "NO",
      "evidence_level": "FROZEN_PROFILE_BOUNDARY",
      "external_gate": "NETWORK_NOT_AUTHORIZED",
      "hardware_claim": "NO",
      "import_grants_capability": "NO",
      "legal": "RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE",
      "security_assurance": "NO",
      "target": "x86_64-systemv-elf-linux",
      "tier": "TARGET_GATED"
    }
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
