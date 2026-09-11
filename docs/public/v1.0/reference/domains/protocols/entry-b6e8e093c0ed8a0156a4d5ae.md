# protocols — neboc protocol fuzz &lt;schema&gt;

In-process protocol model only; no HTTP2/QUIC network transport or service deployment; original observation: real CLI reports bounded local corpus and canonical fuzz runner; SDK bounds: {"MAX_DEDUPLICATION":256,"MAX_FIELDS":64,"MAX_MESSAGE_BYTES":65536,"MAX_METADATA_BYTES":4096,"MAX_REPEATED":4096,"MAX_RETRIES":8,"MAX_STREAM_CAPACITY":64}

```text
Identity: owner:G040:G040-S07-08 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
neboc protocol fuzz tests/rf46-g40/f05/fixtures/echo.nps
```

## Local CLI boundary

Validates local schema and reports the bounded helper workflow. No external protocol connection or deployed service is claimed.

## Invocation and independent observation

{"boundary": "Validates local schema and reports the bounded helper workflow. No external protocol connection or deployed service is claimed.", "deterministic": true, "execution": "LOCAL_CLI_BOUNDARY", "identity": "owner:G040:G040-S07-08", "independent_oracle": "Versioned schema accepted and correct local helper selected.", "input_context": {"argv": \["protocol", "fuzz", "tests/rf46-g40/f05/fixtures/echo.nps"\], "files": {"tests/rf46-g40/f05/fixtures/echo.nps": "NEBO-PROTOCOL-SCHEMA-V1\nprotocol Echo 1\nmessage EchoRequest\nfield 1 required text value 1\nfield 2 repeated u64 tags 8\nmessage EchoResponse\nfield 1 required text value 1\nrpc 1 unary Echo EchoRequest EchoResponse idempotent\nrpc 2 server_stream EchoMany EchoRequest EchoResponse\n"}}, "owner": "compiler/driver/cli/linux-x86_64/cli_driver.asm", "result": "PASS", "signature": "neboc protocol fuzz tests/rf46-g40/f05/fixtures/echo.nps", "stdout_bytes": 198, "stdout_sha256": "ad2b5b993a2de4fbe9fb20746138efd4071f664e00756e3de0864be252b76999", "stdout_text": "protocol-fuzz v1\nschema-format=NEBO-PROTOCOL-SCHEMA-V1\ncorpus=frames,state-machines,schema-mutations\nlimits=frame:65536;queue:64;seed:4007\nnetwork=FORBIDDEN\nrunner=scripts/rf46-g40/protocol_fuzz.py\n"}

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

In-process protocol model only; no HTTP2/QUIC network transport or service deployment; original observation: real CLI reports bounded local corpus and canonical fuzz runner; SDK bounds: {"MAX_DEDUPLICATION":256,"MAX_FIELDS":64,"MAX_MESSAGE_BYTES":65536,"MAX_METADATA_BYTES":4096,"MAX_REPEATED":4096,"MAX_RETRIES":8,"MAX_STREAM_CAPACITY":64}

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
    "boundary": "Validates local schema and reports the bounded helper workflow. No external protocol connection or deployed service is claimed.",
    "deterministic": true,
    "execution": "LOCAL_CLI_BOUNDARY",
    "identity": "owner:G040:G040-S07-08",
    "independent_oracle": "Versioned schema accepted and correct local helper selected.",
    "input_context": {
      "argv": [
        "protocol",
        "fuzz",
        "tests/rf46-g40/f05/fixtures/echo.nps"
      ],
      "files": {
        "tests/rf46-g40/f05/fixtures/echo.nps": "NEBO-PROTOCOL-SCHEMA-V1\nprotocol Echo 1\nmessage EchoRequest\nfield 1 required text value 1\nfield 2 repeated u64 tags 8\nmessage EchoResponse\nfield 1 required text value 1\nrpc 1 unary Echo EchoRequest EchoResponse idempotent\nrpc 2 server_stream EchoMany EchoRequest EchoResponse\n"
      }
    },
    "owner": "compiler/driver/cli/linux-x86_64/cli_driver.asm",
    "result": "PASS",
    "signature": "neboc protocol fuzz tests/rf46-g40/f05/fixtures/echo.nps",
    "stdout_bytes": 198,
    "stdout_sha256": "ad2b5b993a2de4fbe9fb20746138efd4071f664e00756e3de0864be252b76999",
    "stdout_text": "protocol-fuzz v1\nschema-format=NEBO-PROTOCOL-SCHEMA-V1\ncorpus=frames,state-machines,schema-mutations\nlimits=frame:65536;queue:64;seed:4007\nnetwork=FORBIDDEN\nrunner=scripts/rf46-g40/protocol_fuzz.py\n"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/driver/cli/linux-x86_64/cli_driver.asm — SHA-256 0005784201af6835cb78990bd7f0800aa5b745fb813a6bd744934254766560ed

- compiler/driver/cli/linux-x86_64/protocol_cli.inc — SHA-256 477788c037579304767f77687913ba16e1636e05901ed5cd5166ad64c311b285

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
