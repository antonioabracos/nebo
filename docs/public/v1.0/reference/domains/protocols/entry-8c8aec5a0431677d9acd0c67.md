# protocols — RpcClient.connect(endpoint,protocol,capability)

In-process protocol model only; no HTTP2/QUIC network transport or service deployment; original observation: client requires local endpoint protocol and rpc authority; SDK bounds: {"MAX_DEDUPLICATION":256,"MAX_FIELDS":64,"MAX_MESSAGE_BYTES":65536,"MAX_METADATA_BYTES":4096,"MAX_REPEATED":4096,"MAX_RETRIES":8,"MAX_STREAM_CAPACITY":64}

```text
Identity: owner:G040:G040-S03-05 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
RpcClient.connect(endpoint: InMemoryEndpoint, protocol: Protocol, capability: Capability) -> 'RpcClient'
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G040/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

In-process protocol model only; no HTTP2/QUIC network transport or service deployment; original observation: client requires local endpoint protocol and rpc authority; SDK bounds: {"MAX_DEDUPLICATION":256,"MAX_FIELDS":64,"MAX_MESSAGE_BYTES":65536,"MAX_METADATA_BYTES":4096,"MAX_REPEATED":4096,"MAX_RETRIES":8,"MAX_STREAM_CAPACITY":64}

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
    "excerpt": "105: capability = Capability.issue(\"LocalRpc\", (\"rpc\",))\n106: client = RpcClient.connect(client_endpoint, protocol, capability)\n107: ok(\"positive\", \"RpcClient.connect\", client.endpoint is client_endpoint and client.capability is capability)\n108: call = client.call(unary, value, {\"deadline\": 30, \"idempotent\": True,\n109:                                   \"idempotencyKey\": \"echo-73\"})",
    "executed_assertions": 169,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 106,
    "source_path": "tests/rf204/G040/sdk_oracle.py",
    "source_sha256": "5c67e2ca70d05490356fd0a3d9785c769b0d230745e419266ff62923e4568f21"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/protocols.py — SHA-256 ca5df5f45354f486d1ac43f699ccbfe84a45d50fda7b9526e3af05b29303d3c8

- runtime/protocol/rpc.asm — SHA-256 01b82393e074c0d877d75f6207181d2fa983085d4c16187db4b0ce649718cc03

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
