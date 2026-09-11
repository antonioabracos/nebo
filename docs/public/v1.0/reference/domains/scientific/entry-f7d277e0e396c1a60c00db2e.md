# scientific — CLI neboc numeric-report &lt;artifact&gt;

Bounded CPU sparse/FFT/solver reference; no arbitrary precision or convergence outside documented limits; original observation: CLI neboc numeric-report &lt;artifact&gt;; SDK bounds: {"MAX_DENSE_CELLS":65536,"MAX_DIMENSION":4096,"MAX_FFT_LENGTH":64,"MAX_GRID_CELLS":65536,"MAX_ITERATIONS":100000,"MAX_NONZERO":65536,"MAX_TRACE":4096}

```text
Identity: owner:G036:G036-S07-07 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
neboc numeric-report bench.json
```

## Local CLI boundary

Validates a bounded local scientific report. No accelerator or benchmark superiority claim.

## Invocation and independent observation

{"boundary": "Validates a bounded local scientific report. No accelerator or benchmark superiority claim.", "deterministic": true, "execution": "LOCAL_CLI_BOUNDARY", "identity": "owner:G036:G036-S07-07", "independent_oracle": "Independent totalWorkUnits=54 from the core case contract.", "input_context": {"argv": \["numeric-report", "bench.json"\], "files": {"bench.json": "{\"cases\":{\"fft\":{\"power\":\[1.0,1.0,1.0,1.0\],\"workUnits\":16},\"root\":{\"error\":5.820766091346741e-11,\"value\":1.4142135623260401,\"workUnits\":35},\"sparse\":{\"value\":\[16.0,15.0\],\"workUnits\":3}},\"context\":{\"absoluteTolerance\":1e-09,\"deterministic\":true,\"dtype\":\"binary64\",\"implementation\":\"bounded-scalar\",\"relativeTolerance\":1e-09,\"rounding\":\"nearest-even\",\"schema\":\"nebo-scientific-context-v1\",\"target\":\"cpu-reference\",\"threads\":1},\"methodology\":\"deterministic logical work units; not wall-clock time\",\"schema\":\"nebo-scientific-bench-v1\",\"sha256\":\"4701675f131bf441c32c3058b00e14ea076eb54df0a135b98215aa2e0e75d7c3\",\"suite\":\"core\"}\n"}}, "owner": "tools/rf204-g036.py", "result": "PASS", "signature": "neboc numeric-report bench.json", "stdout_bytes": 246, "stdout_sha256": "4f4743dfd35a48c7c3d2c2b888b4ef4fbb86ed0727e965216f27e75ed3b71932", "stdout_text": "{\"artifactSha256\":\"5534b28948743abbf14ffdcd78d188bbfe1c075d697eb5f2be2a23f8a628bacd\",\"cases\":\[\"fft\",\"root\",\"sparse\"\],\"schema\":\"nebo-numeric-report-v1\",\"sourceSchema\":\"nebo-scientific-bench-v1\",\"status\":\"valid\",\"suite\":\"core\",\"totalWorkUnits\":54}\n"}

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded CPU sparse/FFT/solver reference; no arbitrary precision or convergence outside documented limits; original observation: CLI neboc numeric-report &lt;artifact&gt;; SDK bounds: {"MAX_DENSE_CELLS":65536,"MAX_DIMENSION":4096,"MAX_FFT_LENGTH":64,"MAX_GRID_CELLS":65536,"MAX_ITERATIONS":100000,"MAX_NONZERO":65536,"MAX_TRACE":4096}

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
    "boundary": "Validates a bounded local scientific report. No accelerator or benchmark superiority claim.",
    "deterministic": true,
    "execution": "LOCAL_CLI_BOUNDARY",
    "identity": "owner:G036:G036-S07-07",
    "independent_oracle": "Independent totalWorkUnits=54 from the core case contract.",
    "input_context": {
      "argv": [
        "numeric-report",
        "bench.json"
      ],
      "files": {
        "bench.json": "{\"cases\":{\"fft\":{\"power\":[1.0,1.0,1.0,1.0],\"workUnits\":16},\"root\":{\"error\":5.820766091346741e-11,\"value\":1.4142135623260401,\"workUnits\":35},\"sparse\":{\"value\":[16.0,15.0],\"workUnits\":3}},\"context\":{\"absoluteTolerance\":1e-09,\"deterministic\":true,\"dtype\":\"binary64\",\"implementation\":\"bounded-scalar\",\"relativeTolerance\":1e-09,\"rounding\":\"nearest-even\",\"schema\":\"nebo-scientific-context-v1\",\"target\":\"cpu-reference\",\"threads\":1},\"methodology\":\"deterministic logical work units; not wall-clock time\",\"schema\":\"nebo-scientific-bench-v1\",\"sha256\":\"4701675f131bf441c32c3058b00e14ea076eb54df0a135b98215aa2e0e75d7c3\",\"suite\":\"core\"}\n"
      }
    },
    "owner": "tools/rf204-g036.py",
    "result": "PASS",
    "signature": "neboc numeric-report bench.json",
    "stdout_bytes": 246,
    "stdout_sha256": "4f4743dfd35a48c7c3d2c2b888b4ef4fbb86ed0727e965216f27e75ed3b71932",
    "stdout_text": "{\"artifactSha256\":\"5534b28948743abbf14ffdcd78d188bbfe1c075d697eb5f2be2a23f8a628bacd\",\"cases\":[\"fft\",\"root\",\"sparse\"],\"schema\":\"nebo-numeric-report-v1\",\"sourceSchema\":\"nebo-scientific-bench-v1\",\"status\":\"valid\",\"suite\":\"core\",\"totalWorkUnits\":54}\n"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- tools/rf204-g036.py — SHA-256 796410cecbf65c8c3b1a380cfe8d2e03af23ba46c58186dc15dc0ef523684a25

- compiler/driver/cli/linux-x86_64/cli_driver.asm — SHA-256 0005784201af6835cb78990bd7f0800aa5b745fb813a6bd744934254766560ed

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
