# probabilistic — neboc probabilistic-report &lt;artifact&gt;

Bounded seeded CPU probability model; no statistical certification or unlimited sampling; original observation: authenticated redacted NBPRB001 fields and digest printed; SDK bounds: {"MAX_ACTIONS":1024,"MAX_CATEGORIES":4096,"MAX_CHAINS":16,"MAX_DRAWS":100000,"MAX_EXACT_STATES":1000000,"MAX_GRAPH_NODES":1024,"MAX_LATENTS":256,"MAX_OUTCOMES":4096,"MAX_PARTICLES":100000,"MAX_PLATE_SIZE":4096}

```text
Identity: owner:G037:G037-S07-09 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
neboc probabilistic-report report.nbpr
```

## Local CLI boundary

Reads a fixed 64-byte redacted report; does not perform inference or expose private samples.

## Invocation and independent observation

{"boundary": "Reads a fixed 64-byte redacted report; does not perform inference or expose private samples.", "deterministic": true, "execution": "LOCAL_CLI_BOUNDARY", "identity": "owner:G037:G037-S07-09", "independent_oracle": "Exact encoded model=37, inference=4, seed=71, diagnostic=1; privacy redacted.", "input_context": {"argv": \["probabilistic-report", "report.nbpr"\], "files": {"report.nbpr": {"bytes_hex": "4e425052423030310100000000000000010000000000000025000000000000000400000000000000470000000000000001000000000000007197b9709bc893cc"}}}, "owner": "compiler/driver/cli/linux-x86_64/probabilistic_report_cli.inc", "result": "PASS", "signature": "neboc probabilistic-report report.nbpr", "stdout_bytes": 180, "stdout_sha256": "4cef18f156e17dc358439ac78109fada8867cf9599206dc9a9a0637ac0634e9c", "stdout_text": "probabilistic-report v1\nmodel=0x0000000000000025\ninference=0x0000000000000004\nseed=0x0000000000000047\ndiagnostics=0x0000000000000001\nprovenance=0xcc93c89b70b99771\nprivacy=redacted\n"}

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded seeded CPU probability model; no statistical certification or unlimited sampling; original observation: authenticated redacted NBPRB001 fields and digest printed; SDK bounds: {"MAX_ACTIONS":1024,"MAX_CATEGORIES":4096,"MAX_CHAINS":16,"MAX_DRAWS":100000,"MAX_EXACT_STATES":1000000,"MAX_GRAPH_NODES":1024,"MAX_LATENTS":256,"MAX_OUTCOMES":4096,"MAX_PARTICLES":100000,"MAX_PLATE_SIZE":4096}

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
    "boundary": "Reads a fixed 64-byte redacted report; does not perform inference or expose private samples.",
    "deterministic": true,
    "execution": "LOCAL_CLI_BOUNDARY",
    "identity": "owner:G037:G037-S07-09",
    "independent_oracle": "Exact encoded model=37, inference=4, seed=71, diagnostic=1; privacy redacted.",
    "input_context": {
      "argv": [
        "probabilistic-report",
        "report.nbpr"
      ],
      "files": {
        "report.nbpr": {
          "bytes_hex": "4e425052423030310100000000000000010000000000000025000000000000000400000000000000470000000000000001000000000000007197b9709bc893cc"
        }
      }
    },
    "owner": "compiler/driver/cli/linux-x86_64/probabilistic_report_cli.inc",
    "result": "PASS",
    "signature": "neboc probabilistic-report report.nbpr",
    "stdout_bytes": 180,
    "stdout_sha256": "4cef18f156e17dc358439ac78109fada8867cf9599206dc9a9a0637ac0634e9c",
    "stdout_text": "probabilistic-report v1\nmodel=0x0000000000000025\ninference=0x0000000000000004\nseed=0x0000000000000047\ndiagnostics=0x0000000000000001\nprovenance=0xcc93c89b70b99771\nprivacy=redacted\n"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/driver/cli/linux-x86_64/probabilistic_report_cli.inc — SHA-256 45fc10da6f43345d3171bcf1c6da638381c54516bdb2881df29c5a48e15dc32b

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
