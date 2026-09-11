# crypto-policy — SecretShare.split(secret,threshold,parties,random)

Synthetic data only; SHA/HMAC functional checks are not implementation security review; no physical zeroization assurance; original observation: threshold and party bounds precede external-review rejection; SDK bounds: {"MAX_CIRCUIT_INPUTS":64,"MAX_CONSTRAINTS":256,"MAX_MPC_OPERATIONS":128,"MAX_PARAMETER_SETS":16,"MAX_PARTICIPANTS":16,"MAX_RANGE_BITS":256,"MAX_TEXT_BYTES":4096,"MAX_TRANSCRIPT_EVENTS":256,"MAX_VAULT_KEYS":64}

```text
Identity: owner:G044:G044-S04-01 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXTERNAL_REVIEW_ONLY
```

## Syntax or signature

```text
SecretShare.split(secret: Any, threshold: int, parties: int, random: Any) -> None
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G044/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## External gate

CRYPTO_IMPLEMENTATION_REVIEW. This gate is not satisfied by documentation or by local functional assertions. This operation is unavailable pending independent implementation review or its hardware gate. The complete executed example gives the exact diagnostic for this operation; a hardware rejection is not a cryptographic review result.

## Availability and maturity

EXTERNAL_REVIEW_ONLY; evidence FAIL_CLOSED_EXTERNAL_GATE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Synthetic data only; SHA/HMAC functional checks are not implementation security review; no physical zeroization assurance; original observation: threshold and party bounds precede external-review rejection; SDK bounds: {"MAX_CIRCUIT_INPUTS":64,"MAX_CONSTRAINTS":256,"MAX_MPC_OPERATIONS":128,"MAX_PARAMETER_SETS":16,"MAX_PARTICIPANTS":16,"MAX_RANGE_BITS":256,"MAX_TEXT_BYTES":4096,"MAX_TRANSCRIPT_EVENTS":256,"MAX_VAULT_KEYS":64}

## Privacy, dependencies and authority

Capability: SYNTHETIC_LOCAL_DATA. Gate: CRYPTO_IMPLEMENTATION_REVIEW. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Additional observations and limits

```text
[
  {
    "classification": {
      "capability": "SYNTHETIC_LOCAL_DATA",
      "core": "NO",
      "evidence_level": "FAIL_CLOSED_EXTERNAL_GATE",
      "external_gate": "CRYPTO_IMPLEMENTATION_REVIEW",
      "hardware_claim": "NO",
      "import_grants_capability": "NO",
      "legal": "RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE",
      "security_assurance": "NO",
      "target": "PYTHON_CPU_REFERENCE",
      "tier": "EXTERNAL_REVIEW_ONLY"
    }
  },
  {
    "excerpt": "115: # S04: unavailable cryptographic sharing and an explicitly non-MPC local transcript state machine.\n116: rejected(lambda: SecretShare.split(b\"synthetic\", 2, 3, b\"random\"),\n117:          \"EXTERNAL-REVIEW-REQUIRED\", \"SecretShare.split(secret,threshold,parties,random)\")\n118: rejected(lambda: SecretShare.combine([b\"share-a\", b\"share-b\"]),\n119:          \"EXTERNAL-REVIEW-REQUIRED\", \"SecretShare.combine(shares)\")",
    "executed_assertions": 114,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 116,
    "source_path": "tests/rf204/G044/sdk_oracle.py",
    "source_sha256": "3546c41f4ce2ebc4173d3a5a5b7ee150c917cf48405f228e6bd648e5a6ac45fb"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/crypto.py — SHA-256 e271bc891bef7f9831370e275e09a5504a6a92b4be38649be5ce91197cfdb697

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
