# robotics — controller.trace()

Deterministic DSP/PID/replay model; no physical actuator, sensor or hard real-time proof; original observation: immutable trace contains the observed error and terms; SDK bounds: {"MAX_LOOP_TICKS":512,"MAX_MATRIX_DIMENSION":16,"MAX_SAMPLES":4096,"MAX_TRANSFORM_POINTS":256}

```text
Identity: owner:G041:G041-S03-08 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
PidController.trace(self) -> tuple[PidStep, ...]
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G041/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Deterministic DSP/PID/replay model; no physical actuator, sensor or hard real-time proof; original observation: immutable trace contains the observed error and terms; SDK bounds: {"MAX_LOOP_TICKS":512,"MAX_MATRIX_DIMENSION":16,"MAX_SAMPLES":4096,"MAX_TRANSFORM_POINTS":256}

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
    "excerpt": "167:     controller.reset({\"integral\": 0.5, \"previousError\": 1.0, \"derivative\": 0.0})\n168:     surface(\"G041-S03-05\", controller.trace() == () and close(controller._integral, 0.5), controller._integral)\n169:     tuned = controller.tune(\"ziegler-nichols-pi\", {\"ultimateGain\": 4.0, \"ultimatePeriod\": 2.0})\n170:     surface(\"G041-S03-06\", close(tuned[\"kp\"], 1.8) and tuned[\"kd\"] == 0.0, dict(tuned))\n171:     stability = controller.stabilityReport({\"processGain\": 2.0, \"timeConstant\": 5.0})",
    "executed_assertions": 151,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 168,
    "source_path": "tests/rf204/G041/sdk_oracle.py",
    "source_sha256": "0e7332b6c17b6bea3d12acf99b8d30146c1de0f9e251c125610ed3b4b4b0352f"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/robotics.py — SHA-256 64712fe32815fb4d6e89a66a733128363aba505b47895c2a1e5ad4f004fa268d

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
