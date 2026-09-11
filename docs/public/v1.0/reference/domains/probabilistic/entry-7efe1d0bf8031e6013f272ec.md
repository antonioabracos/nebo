# probabilistic — variational.convergenceTrace()

Bounded seeded CPU probability model; no statistical certification or unlimited sampling; original observation: residual decreases across bounded iterations; SDK bounds: {"MAX_ACTIONS":1024,"MAX_CATEGORIES":4096,"MAX_CHAINS":16,"MAX_DRAWS":100000,"MAX_EXACT_STATES":1000000,"MAX_GRAPH_NODES":1024,"MAX_LATENTS":256,"MAX_OUTCOMES":4096,"MAX_PARTICLES":100000,"MAX_PLATE_SIZE":4096}

```text
Identity: owner:G037:G037-S05-07 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
VariationalResult.convergenceTrace(self) -> tuple[Mapping[str, Any], ...]
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G037/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded seeded CPU probability model; no statistical certification or unlimited sampling; original observation: residual decreases across bounded iterations; SDK bounds: {"MAX_ACTIONS":1024,"MAX_CATEGORIES":4096,"MAX_CHAINS":16,"MAX_DRAWS":100000,"MAX_EXACT_STATES":1000000,"MAX_GRAPH_NODES":1024,"MAX_LATENTS":256,"MAX_OUTCOMES":4096,"MAX_PARTICLES":100000,"MAX_PLATE_SIZE":4096}

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
    "excerpt": "153: ok(\"positive\", \"variational.posterior\", close(variational_posterior.mean(), 2.0, 1e-12))\n154: trace = variational.convergenceTrace()\n155: ok(\"positive\", \"variational.convergenceTrace\",\n156:    len(trace) > 1 and trace[-1][\"residual\"] < trace[0][\"residual\"])\n157: comparison = variational.compareMcmc(samples)",
    "executed_assertions": 169,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 154,
    "source_path": "tests/rf204/G037/sdk_oracle.py",
    "source_sha256": "9781fd42d9a09308329071fec9eb14961dbd34c6cae327beb938ab51e12ba651"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/probabilistic.py — SHA-256 2b2541e579e3f6222d99527a67dc7fa00bfb2ab9aa648663f1eb801a15a71535

- runtime/probabilistic/variational.asm — SHA-256 0cbfa48b7cb442eecb9f4cfe50ff9dd9e544f3223ef26ef8a0268cfc7d97a94a

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
