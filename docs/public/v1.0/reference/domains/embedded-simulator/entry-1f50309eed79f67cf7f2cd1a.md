# embedded-simulator — neboc firmware build --board &lt;id&gt;

Simulator only; no physical board, interrupt latency or real-time certification; original observation: real CLI reports deterministic simulator-only ELF and raw image support; SDK bounds: {"MAX_IMAGE_BYTES":262144,"MAX_TASKS":32,"MAX_TRACE_EVENTS":4096,"MAX_TRANSFER_BYTES":4096}

```text
Identity: owner:G038:G038-S01-08 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
neboc firmware build --board NEBO_REFERENCE_BOARD_SIM_V1
```

## Local CLI boundary

This command reports the reference-board profile and bounded simulator contract. Its stdout does not prove a firmware compilation, boot, interrupt timing or physical board execution.

## Invocation and independent observation

{"boundary": "This command reports the reference-board profile and bounded simulator contract. Its stdout does not prove a firmware compilation, boot, interrupt timing or physical board execution.", "deterministic": true, "execution": "LOCAL_CLI_BOUNDARY", "identity": "owner:G038:G038-S01-08", "independent_oracle": "Only the supported simulator descriptor is accepted; hardware=false.", "input_context": {"argv": \["firmware", "build", "--board", "NEBO_REFERENCE_BOARD_SIM_V1"\], "files": {}}, "owner": "compiler/driver/cli/linux-x86_64/cli_driver.asm", "result": "PASS", "signature": "neboc firmware build --board NEBO_REFERENCE_BOARD_SIM_V1", "stdout_bytes": 139, "stdout_sha256": "1d2eda28f2c689e4d9d1d8e2868eec3a27cac990c6aef1893b1c53b644a1a3e0", "stdout_text": "firmware-build v1\nboard=NEBO_REFERENCE_BOARD_SIM_V1\ntarget=x86_64-nebo-reference-none\nimage=elf64+raw-bin\ndeterministic=yes\nhardware=false\n"}

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Simulator only; no physical board, interrupt latency or real-time certification; original observation: real CLI reports deterministic simulator-only ELF and raw image support; SDK bounds: {"MAX_IMAGE_BYTES":262144,"MAX_TASKS":32,"MAX_TRACE_EVENTS":4096,"MAX_TRANSFER_BYTES":4096}

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
    "boundary": "This command reports the reference-board profile and bounded simulator contract. Its stdout does not prove a firmware compilation, boot, interrupt timing or physical board execution.",
    "deterministic": true,
    "execution": "LOCAL_CLI_BOUNDARY",
    "identity": "owner:G038:G038-S01-08",
    "independent_oracle": "Only the supported simulator descriptor is accepted; hardware=false.",
    "input_context": {
      "argv": [
        "firmware",
        "build",
        "--board",
        "NEBO_REFERENCE_BOARD_SIM_V1"
      ],
      "files": {}
    },
    "owner": "compiler/driver/cli/linux-x86_64/cli_driver.asm",
    "result": "PASS",
    "signature": "neboc firmware build --board NEBO_REFERENCE_BOARD_SIM_V1",
    "stdout_bytes": 139,
    "stdout_sha256": "1d2eda28f2c689e4d9d1d8e2868eec3a27cac990c6aef1893b1c53b644a1a3e0",
    "stdout_text": "firmware-build v1\nboard=NEBO_REFERENCE_BOARD_SIM_V1\ntarget=x86_64-nebo-reference-none\nimage=elf64+raw-bin\ndeterministic=yes\nhardware=false\n"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/driver/cli/linux-x86_64/cli_driver.asm — SHA-256 0005784201af6835cb78990bd7f0800aa5b745fb813a6bd744934254766560ed

- compiler/driver/cli/linux-x86_64/firmware_cli.inc — SHA-256 88dc5d71703605c1b53886197b236fb788bcabf8bb0fe33400d9b477d7102959

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
