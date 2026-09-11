# ai-agents — Prompt.new(parts)

Offline tokenizer/generation/agent reference model; no service, network or foundation-model claim; original observation: role-tagged prompt renders from bounded explicit parts; SDK bounds: {"MAX_CONTEXT":4096,"MAX_EVALUATION_CASES":256,"MAX_GENERATED_TOKENS":256,"MAX_MANIFEST_BYTES":65536,"MAX_PLAN_STEPS":32,"MAX_SCHEMA_FIELDS":64,"MAX_TEXT_BYTES":8192,"MAX_TOOLS":32,"MAX_TOOL_ARGUMENTS":16,"MAX_VOCABULARY":512}

```text
Identity: owner:G023:G023-S04-01 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
Prompt.new(cls, parts: Sequence[Mapping[str, Any]]) -> 'Prompt'
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G023/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Offline tokenizer/generation/agent reference model; no service, network or foundation-model claim; original observation: role-tagged prompt renders from bounded explicit parts; SDK bounds: {"MAX_CONTEXT":4096,"MAX_EVALUATION_CASES":256,"MAX_GENERATED_TOKENS":256,"MAX_MANIFEST_BYTES":65536,"MAX_PLAN_STEPS":32,"MAX_SCHEMA_FIELDS":64,"MAX_TEXT_BYTES":8192,"MAX_TOOLS":32,"MAX_TOOL_ARGUMENTS":16,"MAX_VOCABULARY":512}

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
    "excerpt": "134:     surface(\"G023-S02-01\", model.vocabulary_size == 15 and model.checksum.startswith(\"441cd387\") and model.quantization == \"none-f64-reference\", model.provenance())\n135:     cache = KvCache.new({\"maximumLength\": 64, \"modelChecksum\": model.checksum})\n136:     result = model.forward((4, 6, 5, 7), cache)\n137:     expected = independent_logits(model, (4, 6, 5, 7))\n138:     surface(\"G023-S02-02\", result.logits == expected and result.operations == 60, result.logits)",
    "executed_assertions": 157,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 135,
    "source_path": "tests/rf204/G023/sdk_oracle.py",
    "source_sha256": "4ca030efbb92a0e7fa584f140398f9f8624078177c454046dca6143200b536a3"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/ai.py — SHA-256 70b14138a269d49cd6f222c4e8a0b91a881d28a292cbca106440e0dd228b43b1

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
