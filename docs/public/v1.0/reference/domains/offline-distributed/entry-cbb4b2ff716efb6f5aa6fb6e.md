# offline-distributed — EventStore.open(path,options,capability)

Local event/convergence model; no network or distributed availability guarantee; original observation: bounded relative store opens under explicit capability; SDK bounds: {"MAX_BATCH":256,"MAX_BYTES":1048576,"MAX_CHANGES":4096,"MAX_EVENTS":4096,"MAX_QUEUE":256,"MAX_REPLICAS":16}

```text
Identity: owner:G033:G033-S01-01 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
EventStore.open(path: str, options: Mapping[str, Any], capability: Capability) -> 'EventStore'
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G033/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Local event/convergence model; no network or distributed availability guarantee; original observation: bounded relative store opens under explicit capability; SDK bounds: {"MAX_BATCH":256,"MAX_BYTES":1048576,"MAX_CHANGES":4096,"MAX_EVENTS":4096,"MAX_QUEUE":256,"MAX_REPLICAS":16}

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
    "excerpt": "55: clock = HybridLogicalClock.new(clock_cap)\n56: store_cap = Capability.issue(\"event-store\", (\"open\", \"append\", \"read\", \"snapshot\",\n57:                                                \"subscribe\", \"verify\"), \"oracle\")\n58: \n59: ",
    "executed_assertions": 177,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 56,
    "source_path": "tests/rf204/G033/sdk_oracle.py",
    "source_sha256": "2de9a622a3eb037c8a9f1ab169d006968b96e37bf0f7bebbe614c9a4b16737f2"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/offline.py — SHA-256 06fa44aad79681e8590903b52c42a691658d84d8ef121282912bc33d4741c4f5

- runtime/eventsourcing/event_store.asm — SHA-256 90f83ce9ea6b2e9c514a2eecf40eba8e92a2af83b27745b06c7495c3a27d1743

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
