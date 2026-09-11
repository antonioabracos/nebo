# embedded-simulator — simulator.injectInterrupt(vector,time)

Simulator only; no physical board, interrupt latency or real-time certification; original observation: vector two handler returns observed value at logical time 200; SDK bounds: {"MAX_IMAGE_BYTES":262144,"MAX_TASKS":32,"MAX_TRACE_EVENTS":4096,"MAX_TRANSFER_BYTES":4096}

```text
Identity: owner:G038:G038-S07-06 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
HardwareSimulator.injectInterrupt(self, vector: int, time: int) -> Any
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G038/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Simulator only; no physical board, interrupt latency or real-time certification; original observation: vector two handler returns observed value at logical time 200; SDK bounds: {"MAX_IMAGE_BYTES":262144,"MAX_TASKS":32,"MAX_TRACE_EVENTS":4096,"MAX_TRANSFER_BYTES":4096}

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
    "excerpt": "93:    binding.latencyBudget(250) is binding and binding.budget_ns == 250)\n94: ok(\"composition\", \"interrupt-injection\", simulator.injectInterrupt(5, 1000) == 38\n95:    and observed_irqs == [\"irq5\"] and binding.pending)\n96: binding.acknowledge()\n97: ok(\"positive\", \"interrupt.acknowledge\", not binding.pending)",
    "executed_assertions": 155,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 94,
    "source_path": "tests/rf204/G038/sdk_oracle.py",
    "source_sha256": "4b85e1cc429dfdf0bfc08318459464f636c00c3df960461e265e643c9e3e1b5c"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/embedded.py — SHA-256 c754e997800e56a17bb014c5ba0adbc5772533bf28655df790ad183b5ccc55f4

- simulators/embedded_reference_v1/reference_board.py — SHA-256 5f901b75282533c5e2ed73fb50a687f1b7e9e720328ade82d7e674acacef36b4

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
