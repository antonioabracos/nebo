# portable-reference — neboc_portable_sbom

Bytecode/component/eBPF reference only; no native non-x86 target backend certification; original observation: artifact kind bytes and digest govern canonical local JSON SBOM; SDK bounds: {"MAX_BPF_INSTRUCTIONS":4096,"MAX_BPF_MAP_ENTRIES":65536,"MAX_CALLS":4096,"MAX_COMPONENTS":32,"MAX_EDGE_STATE_BYTES":1048576,"MAX_EXPORTS":128,"MAX_IMPORTS":128,"MAX_INPUT_BYTES":1048576,"MAX_INTERFACE_FUNCTIONS":128,"MAX_MEMORY_PAGES":4096,"MAX_SOURCE_BYTES":1048576,"MAX_TABLE_ITEMS":65536}

```text
Identity: owner:G039:G039-S06-07 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
neboc portable-sbom sample.wasm
```

## Local CLI boundary

Reports local artifact structure, size and digest; it is not a release SBOM or security review.

## Invocation and independent observation

{"boundary": "Reports local artifact structure, size and digest; it is not a release SBOM or security review.", "deterministic": true, "execution": "LOCAL_CLI_BOUNDARY", "identity": "owner:G039:G039-S06-07", "independent_oracle": "Independent artifact byte length and FNV-1a digest.", "input_context": {"argv": \["portable-sbom", "sample.wasm"\], "files": {"sample.wasm": "Generate with neboc emit-wasm source.no."}}, "owner": "compiler/driver/cli/linux-x86_64/portable_cli.inc", "result": "PASS", "signature": "neboc portable-sbom sample.wasm", "stdout_bytes": 148, "stdout_sha256": "c58e0300dfd2b4a675046c96b2b8758fb61f49e699dc6a725aeb356b2b2237df", "stdout_text": "{\"schema\":1,\"format\":\"NEBO-PORTABLE-SBOM-v1\",\"kind\":\"wasm32\",\"bytes\":28,\"fnv1a64\":\"0xf9a306b99a9fff7d\",\"network\":false,\"kernelLoad\":\"NOT_EXECUTED\"}\n"}

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bytecode/component/eBPF reference only; no native non-x86 target backend certification; original observation: artifact kind bytes and digest govern canonical local JSON SBOM; SDK bounds: {"MAX_BPF_INSTRUCTIONS":4096,"MAX_BPF_MAP_ENTRIES":65536,"MAX_CALLS":4096,"MAX_COMPONENTS":32,"MAX_EDGE_STATE_BYTES":1048576,"MAX_EXPORTS":128,"MAX_IMPORTS":128,"MAX_INPUT_BYTES":1048576,"MAX_INTERFACE_FUNCTIONS":128,"MAX_MEMORY_PAGES":4096,"MAX_SOURCE_BYTES":1048576,"MAX_TABLE_ITEMS":65536}

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
    "boundary": "Reports local artifact structure, size and digest; it is not a release SBOM or security review.",
    "deterministic": true,
    "execution": "LOCAL_CLI_BOUNDARY",
    "identity": "owner:G039:G039-S06-07",
    "independent_oracle": "Independent artifact byte length and FNV-1a digest.",
    "input_context": {
      "argv": [
        "portable-sbom",
        "sample.wasm"
      ],
      "files": {
        "sample.wasm": "Generate with neboc emit-wasm source.no."
      }
    },
    "owner": "compiler/driver/cli/linux-x86_64/portable_cli.inc",
    "result": "PASS",
    "signature": "neboc portable-sbom sample.wasm",
    "stdout_bytes": 148,
    "stdout_sha256": "c58e0300dfd2b4a675046c96b2b8758fb61f49e699dc6a725aeb356b2b2237df",
    "stdout_text": "{\"schema\":1,\"format\":\"NEBO-PORTABLE-SBOM-v1\",\"kind\":\"wasm32\",\"bytes\":28,\"fnv1a64\":\"0xf9a306b99a9fff7d\",\"network\":false,\"kernelLoad\":\"NOT_EXECUTED\"}\n"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/driver/cli/linux-x86_64/portable_cli.inc — SHA-256 9a47b429b5ac7f82ed06140c7409517bfa734334f74a38a9eab1250b142341d6

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
