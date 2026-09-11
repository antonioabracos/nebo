# training — gradients.zero()

Bounded CPU reference gradients and local checkpoint model; no large-model training claim; original observation: gradients.zero(); SDK bounds: {"MAX_BATCH":64,"MAX_CHECKPOINT_BYTES":1048576,"MAX_ELEMENTS":4096,"MAX_EPOCHS":1024,"MAX_GRAPH_NODES":256,"MAX_PARAMETERS":4096,"MAX_PREFETCH":8,"MAX_ROTATIONS":8,"MAX_SAMPLES":4096}

```text
Identity: owner:G021:G021-S02-03 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
GradientSet.zero(self) -> int
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G021/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded CPU reference gradients and local checkpoint model; no large-model training claim; original observation: gradients.zero(); SDK bounds: {"MAX_BATCH":64,"MAX_CHECKPOINT_BYTES":1048576,"MAX_ELEMENTS":4096,"MAX_EPOCHS":1024,"MAX_GRAPH_NODES":256,"MAX_PARAMETERS":4096,"MAX_PREFETCH":8,"MAX_ROTATIONS":8,"MAX_SAMPLES":4096}

## Privacy, dependencies and authority

Capability: SYNTHETIC_LOCAL_DATA. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Additional observations and limits

```text
[
  {
    "classification": {
      "capability": "SYNTHETIC_LOCAL_DATA",
      "core": "NO",
      "evidence_level": "SDK_REFERENCE_MODEL",
      "external_gate": "NONE",
      "hardware_claim": "NO",
      "import_grants_capability": "NO",
      "legal": "RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE",
      "security_assurance": "NO",
      "target": "PYTHON_CPU_REFERENCE",
      "tier": "EXPERIMENTAL"
    }
  },
  {
    "excerpt": "93: ok(\"positive\", \"tensor.backward\", vector.gradient().values == (6.0, 8.0))\n94: zeroed = gradients.zero()\n95: ok(\"positive\", \"gradients.zero\", zeroed >= 3 and vector.gradient().values == (0.0, 0.0))\n96: vector._gradient = [3.0, 4.0]\n97: observed_norm = gradients.clipNorm(2.5)",
    "executed_assertions": 161,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 94,
    "source_path": "tests/rf204/G021/sdk_oracle.py",
    "source_sha256": "5a1429db6bd8425cf0a66c0554c80e3acce560039457d664b79963e416a431bf"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/training.py — SHA-256 bc356ec80945191c20dd9e64386d9b4d7f82375cbcb42c1bd8992455bba7e421

- runtime/autograd/backward.asm — SHA-256 091ac60a12552e7171d160962d54c54a48fa3004951368e1fa902c2d2f9b0080

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
