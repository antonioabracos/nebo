# workflows — neboc-workflow-verify

Bounded local workflow/agent state machine; no remote scheduler or external side effects; original observation: valid definition passes and incomplete definition fails; SDK bounds: {"MAX_ATTEMPTS":8,"MAX_DOMAIN_CASES":256,"MAX_HISTORY":256,"MAX_ROWS":64,"MAX_RULES":64,"MAX_SAGA_STEPS":16,"MAX_STATES":128,"MAX_STEPS":64,"MAX_TRANSITIONS":1024}

```text
Identity: owner:G045:G045-S07-08 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
neboc workflow verify tests/rf204/G045/cases/valid.workflow
```

## Local CLI boundary

Reads a bounded versioned local workflow definition. Does not schedule tasks, contact services or mutate the workflow.

## Invocation and independent observation

{"boundary": "Reads a bounded versioned local workflow definition. Does not schedule tasks, contact services or mutate the workflow.", "deterministic": true, "execution": "LOCAL_CLI_BOUNDARY", "identity": "owner:G045:G045-S07-08", "independent_oracle": "Versioned contract and mutation=NO; malformed input rejects.", "input_context": {"argv": \["workflow", "verify", "tests/rf204/G045/cases/valid.workflow"\], "files": {"tests/rf204/G045/cases/valid.workflow": "NEBO-WORKFLOW-V1\nname=fulfil-order\nversion=2\ninitial=pending\nstate=pending\nstate=reserved\ntransition=pending,reserve,reserved\nstep=reserve-stock\nidempotency=order-identity\ncompensation=release-stock\nrule=eligible-order\ndecision=priority-band\n"}}, "owner": "compiler/driver/cli/linux-x86_64/workflow_cli.inc", "result": "PASS", "signature": "neboc workflow verify tests/rf204/G045/cases/valid.workflow", "stdout_bytes": 166, "stdout_sha256": "d1cb2c7bf1c1ec7d550a440cf186abc3cda20e28702347f797b9ebf7ed293ec8", "stdout_text": "workflow-verify v1\nformat=NEBO-WORKFLOW-V1\nversioned=YES\nstate-machine=YES\ndurable-steps=YES\nidempotency=EXPLICIT\ncompensation=EXPLICIT\nmutation=NO\nnetwork=FORBIDDEN\n"}

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded local workflow/agent state machine; no remote scheduler or external side effects; original observation: valid definition passes and incomplete definition fails; SDK bounds: {"MAX_ATTEMPTS":8,"MAX_DOMAIN_CASES":256,"MAX_HISTORY":256,"MAX_ROWS":64,"MAX_RULES":64,"MAX_SAGA_STEPS":16,"MAX_STATES":128,"MAX_STEPS":64,"MAX_TRANSITIONS":1024}

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
    "boundary": "Reads a bounded versioned local workflow definition. Does not schedule tasks, contact services or mutate the workflow.",
    "deterministic": true,
    "execution": "LOCAL_CLI_BOUNDARY",
    "identity": "owner:G045:G045-S07-08",
    "independent_oracle": "Versioned contract and mutation=NO; malformed input rejects.",
    "input_context": {
      "argv": [
        "workflow",
        "verify",
        "tests/rf204/G045/cases/valid.workflow"
      ],
      "files": {
        "tests/rf204/G045/cases/valid.workflow": "NEBO-WORKFLOW-V1\nname=fulfil-order\nversion=2\ninitial=pending\nstate=pending\nstate=reserved\ntransition=pending,reserve,reserved\nstep=reserve-stock\nidempotency=order-identity\ncompensation=release-stock\nrule=eligible-order\ndecision=priority-band\n"
      }
    },
    "owner": "compiler/driver/cli/linux-x86_64/workflow_cli.inc",
    "result": "PASS",
    "signature": "neboc workflow verify tests/rf204/G045/cases/valid.workflow",
    "stdout_bytes": 166,
    "stdout_sha256": "d1cb2c7bf1c1ec7d550a440cf186abc3cda20e28702347f797b9ebf7ed293ec8",
    "stdout_text": "workflow-verify v1\nformat=NEBO-WORKFLOW-V1\nversioned=YES\nstate-machine=YES\ndurable-steps=YES\nidempotency=EXPLICIT\ncompensation=EXPLICIT\nmutation=NO\nnetwork=FORBIDDEN\n"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/driver/cli/linux-x86_64/workflow_cli.inc — SHA-256 2ed3234ac326f3f2e023559c1991530cb808bc5cd3c86badb111d279ef18a8fc

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
