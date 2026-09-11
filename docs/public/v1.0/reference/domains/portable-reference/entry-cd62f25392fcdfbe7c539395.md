# portable-reference — neboc_portable_test

Bytecode/component/eBPF reference only; no native non-x86 target backend certification; original observation: artifact bytes govern kind structural validation byte count and digest; SDK bounds: {"MAX_BPF_INSTRUCTIONS":4096,"MAX_BPF_MAP_ENTRIES":65536,"MAX_CALLS":4096,"MAX_COMPONENTS":32,"MAX_EDGE_STATE_BYTES":1048576,"MAX_EXPORTS":128,"MAX_IMPORTS":128,"MAX_INPUT_BYTES":1048576,"MAX_INTERFACE_FUNCTIONS":128,"MAX_MEMORY_PAGES":4096,"MAX_SOURCE_BYTES":1048576,"MAX_TABLE_ITEMS":65536}

```text
Identity: owner:G039:G039-S06-06 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
neboc portable-test sample.bpf
```

## Local CLI boundary

Validates the bounded BPF instruction envelope; no kernel loading.

## Invocation and independent observation

{"boundary": "Validates the bounded BPF instruction envelope; no kernel loading.", "deterministic": true, "execution": "LOCAL_CLI_BOUNDARY", "identity": "owner:G039:G039-S06-06", "independent_oracle": "16-byte static envelope, no network or kernel execution.", "input_context": {"argv": \["portable-test", "sample.bpf"\], "files": {"sample.bpf": "Generate with neboc emit-bpf source.no; source.no is displayed on the emit-bpf page."}}, "owner": "compiler/driver/cli/linux-x86_64/portable_cli.inc", "result": "PASS", "signature": "neboc portable-test sample.bpf", "stdout_bytes": 157, "stdout_sha256": "38b8eb3878e0dcc70c517a9f4f1aefb45efabc1115d03abd2005e846775834c3", "stdout_text": "portable-test v1\nkind=ebpf-static-subset\nvalidation=PASS\nkernel-load=NOT_EXECUTED\nbytes=16\nfnv1a64=0x7f26f31afb67cb53\nnetwork=FORBIDDEN\nambient-authority=NO\n"}

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bytecode/component/eBPF reference only; no native non-x86 target backend certification; original observation: artifact bytes govern kind structural validation byte count and digest; SDK bounds: {"MAX_BPF_INSTRUCTIONS":4096,"MAX_BPF_MAP_ENTRIES":65536,"MAX_CALLS":4096,"MAX_COMPONENTS":32,"MAX_EDGE_STATE_BYTES":1048576,"MAX_EXPORTS":128,"MAX_IMPORTS":128,"MAX_INPUT_BYTES":1048576,"MAX_INTERFACE_FUNCTIONS":128,"MAX_MEMORY_PAGES":4096,"MAX_SOURCE_BYTES":1048576,"MAX_TABLE_ITEMS":65536}

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
    "boundary": "Validates the bounded BPF instruction envelope; no kernel loading.",
    "deterministic": true,
    "execution": "LOCAL_CLI_BOUNDARY",
    "identity": "owner:G039:G039-S06-06",
    "independent_oracle": "16-byte static envelope, no network or kernel execution.",
    "input_context": {
      "argv": [
        "portable-test",
        "sample.bpf"
      ],
      "files": {
        "sample.bpf": "Generate with neboc emit-bpf source.no; source.no is displayed on the emit-bpf page."
      }
    },
    "owner": "compiler/driver/cli/linux-x86_64/portable_cli.inc",
    "result": "PASS",
    "signature": "neboc portable-test sample.bpf",
    "stdout_bytes": 157,
    "stdout_sha256": "38b8eb3878e0dcc70c517a9f4f1aefb45efabc1115d03abd2005e846775834c3",
    "stdout_text": "portable-test v1\nkind=ebpf-static-subset\nvalidation=PASS\nkernel-load=NOT_EXECUTED\nbytes=16\nfnv1a64=0x7f26f31afb67cb53\nnetwork=FORBIDDEN\nambient-authority=NO\n"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/driver/cli/linux-x86_64/portable_cli.inc — SHA-256 9a47b429b5ac7f82ed06140c7409517bfa734334f74a38a9eab1250b142341d6

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
