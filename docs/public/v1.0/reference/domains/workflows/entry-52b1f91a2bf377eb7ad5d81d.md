# workflows — state.on(event,target,guard,action)

Bounded local workflow/agent state machine; no remote scheduler or external side effects; original observation: approve owns one guarded transition and action; SDK bounds: {"MAX_ATTEMPTS":8,"MAX_DOMAIN_CASES":256,"MAX_HISTORY":256,"MAX_ROWS":64,"MAX_RULES":64,"MAX_SAGA_STEPS":16,"MAX_STATES":128,"MAX_STEPS":64,"MAX_TRANSITIONS":1024}

```text
Identity: owner:G045:G045-S01-03 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
State.on(self, event: str, target: str, guard: Callable[[Mapping[str, Any]], bool] | None=None, action: Callable[[dict[str, Any]], Any] | None=None) -> 'State'
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G045/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded local workflow/agent state machine; no remote scheduler or external side effects; original observation: approve owns one guarded transition and action; SDK bounds: {"MAX_ATTEMPTS":8,"MAX_DOMAIN_CASES":256,"MAX_HISTORY":256,"MAX_ROWS":64,"MAX_RULES":64,"MAX_SAGA_STEPS":16,"MAX_STATES":128,"MAX_STEPS":64,"MAX_TRANSITIONS":1024}

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
    "excerpt": "59: ok(\"positive\", \"machine.state\", pending.name == \"pending\" and approved.name == \"approved\")\n60: pending.on(\"approve\", \"approved\", lambda ctx: ctx[\"amount\"] <= 500,\n61:            lambda ctx: {**ctx, \"approvedBy\": \"policy-45\"})\n62: ok(\"positive\", \"state.on\", tuple(pending.transitions) == (\"approve\",))\n63: transition = machine.send(\"approve\", {\"amount\": 145})",
    "executed_assertions": 159,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 60,
    "source_path": "tests/rf204/G045/sdk_oracle.py",
    "source_sha256": "975dfebd8d5639e9607ca8a4d524d8f32a89a22e3d6225ce66a7cd52d9904bc9"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/workflows.py — SHA-256 8def85efce57e95e308d68a5b633698239e42eecdabc5df9950776fbb969e070

- runtime/workflow/fsm.asm — SHA-256 17e82a479f921a164c8d4307575140255cdb477e1dc3baedf8e766d01a689b2c

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
