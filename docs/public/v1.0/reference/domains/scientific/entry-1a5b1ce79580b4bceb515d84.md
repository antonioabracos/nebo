# scientific — sparse.transpose()

Bounded CPU sparse/FFT/solver reference; no arbitrary precision or convergence outside documented limits; original observation: sparse.transpose(); SDK bounds: {"MAX_DENSE_CELLS":65536,"MAX_DIMENSION":4096,"MAX_FFT_LENGTH":64,"MAX_GRID_CELLS":65536,"MAX_ITERATIONS":100000,"MAX_NONZERO":65536,"MAX_TRACE":4096}

```text
Identity: owner:G036:G036-S01-06 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
SparseMatrix.transpose(self) -> 'SparseMatrix'
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G036/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded CPU sparse/FFT/solver reference; no arbitrary precision or convergence outside documented limits; original observation: sparse.transpose(); SDK bounds: {"MAX_DENSE_CELLS":65536,"MAX_DIMENSION":4096,"MAX_FFT_LENGTH":64,"MAX_GRID_CELLS":65536,"MAX_ITERATIONS":100000,"MAX_NONZERO":65536,"MAX_TRACE":4096}

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
    "excerpt": "54: ok(\"positive\", \"sparse.density\", csr.density() == 0.5)\n55: transposed = csr.transpose()\n56: ok(\"positive\", \"sparse.transpose\", transposed.toDense(6) == ((1.0, 0.0), (0.0, 3.0), (2.0, 0.0)))\n57: product = csr.matmul((4, 5, 6))\n58: ok(\"positive\", \"sparse.matmul\", product == (16.0, 15.0))",
    "executed_assertions": 150,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 55,
    "source_path": "tests/rf204/G036/sdk_oracle.py",
    "source_sha256": "9677a246f00fbc68f5693efadd33a4c9eeb8ac6c416dd126bfad707826b5d137"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/scientific.py — SHA-256 bb007e9d203c5c6a54248e5a8ec5190442fc56cf84afe1a7213c8832ec370294

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
