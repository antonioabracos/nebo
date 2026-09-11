# media — G019-S03-F002

Bounded native media owner; legacy whole-file source probe is not a public typed API; original observation: image.crop copies the exact bounded source rectangle

```text
Identity: owner:G019:G019-S03-F002 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EXCLUDED_1_0
```

## Syntax or signature

```text
G019-S03-F002
Owner: runtime/image/image_transform.asm::nebo_image_crop_into
```

## Internal owner boundary

This is an internal owner contract, currently excluded from the public Edition 1 API. The original owner record may describe multiple observations. Its count is a contract-record count, not a count of callable native functions. Use the admitted receiver-first source pages where available. No historical example is presented as newly executed.

## Availability and maturity

EXCLUDED_1_0; evidence NATIVE_OWNER_RECORD. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded native media owner; legacy whole-file source probe is not a public typed API; original observation: image.crop copies the exact bounded source rectangle

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Additional observations and limits

```text
[
  {
    "classification": {
      "capability": "NONE",
      "core": "NO",
      "evidence_level": "NATIVE_OWNER_RECORD",
      "external_gate": "NONE",
      "hardware_claim": "NO",
      "import_grants_capability": "NO",
      "legal": "RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE",
      "security_assurance": "NO",
      "target": "x86_64-systemv-elf-linux",
      "tier": "EXCLUDED_1_0"
    }
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- runtime/image/image_transform.asm — SHA-256 8eac67add3fb4e363f998e065b9a413467ca5d83e556e0cae8f23dd7bd917142

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
