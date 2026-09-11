# inference — Model.load(path, options)

Bounded CPU model, synthetic local weights only; no downloaded model or GPU claim; original observation: Model.load(path, options); SDK bounds: {"MAX_BATCH":16,"MAX_DIMENSION":64,"MAX_ELEMENTS":4096,"MAX_LAYERS":64,"MAX_MODEL_BYTES":1048576,"MAX_WARMUP":16,"MAX_WORKSPACE_BYTES":1048576}

```text
Identity: owner:G020:G020-S05-02 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
Model.load(path: str | os.PathLike[str], options: Mapping[str, Any] | None=None) -> 'Model'
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G020/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded CPU model, synthetic local weights only; no downloaded model or GPU claim; original observation: Model.load(path, options); SDK bounds: {"MAX_BATCH":16,"MAX_DIMENSION":64,"MAX_ELEMENTS":4096,"MAX_LAYERS":64,"MAX_MODEL_BYTES":1048576,"MAX_WARMUP":16,"MAX_WORKSPACE_BYTES":1048576}

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
    "excerpt": "162:    inspected[\"version\"] == 1 and len(inspected[\"checksum\"]) == 64)\n163: loaded = Model.load(model_path, {\"maxBytes\": 8192})\n164: ok(\"positive\", \"Model.load\", close_values(loaded.forward(sample), model.forward(sample)))\n165: weights = Weights.load(model_path, {\"0.weight\": \"copied.weight\"})\n166: ok(\"positive\", \"Weights.load\", weights[\"copied.weight\"].values == linear.weight.values)",
    "executed_assertions": 150,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 163,
    "source_path": "tests/rf204/G020/sdk_oracle.py",
    "source_sha256": "6a6da775c3ff50ba50e057d883485d839a521fb8e89e5ce418237992d715350b"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/ml_inference.py — SHA-256 5cddea5b14b580ae248b257fcdc64002e0d09480122379b5591a87d62b84767f

- runtime/ml/model_format.asm — SHA-256 ece9ba6ec3b2faf3db4a7b36bb74e2051e76f33a0fae0131aae03bd1e26eb43d

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
