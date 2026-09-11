# spatial — neboc-geometry-check

Local bounded geometry/GIS; no external maps or global navigation assurance; original observation: valid document passes and incomplete document fails; SDK bounds: {"MAX_CODEC_BYTES":65536,"MAX_FACES":8192,"MAX_INDEX_ITEMS":4096,"MAX_POINTS":4096,"MAX_ROUTE_EDGES":8192,"MAX_ROUTE_NODES":2048}

```text
Identity: owner:G042:G042-S07-07 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
neboc geometry-check tests/rf204/G042/cases/valid.geometry
```

## Local CLI boundary

Bounded local document validation. Geometry topology is not evaluated; route-bench reports declared cases, not measured route timings.

## Invocation and independent observation

{"boundary": "Bounded local document validation. Geometry topology is not evaluated; route-bench reports declared cases, not measured route timings.", "deterministic": true, "execution": "LOCAL_CLI_BOUNDARY", "identity": "owner:G042:G042-S07-07", "independent_oracle": "Exact validated user payload is reported; malformed versioned input rejects.", "input_context": {"argv": \["geometry-check", "tests/rf204/G042/cases/valid.geometry"\], "files": {"tests/rf204/G042/cases/valid.geometry": "NEBO-GEOMETRY-V1\nprecision=exact\ncrs=LOCAL-CARTESIAN-V1\nunits=millimetre\ngeometry=POLYGON((0 0,8 0,8 5,0 0))\n"}}, "owner": "compiler/driver/cli/linux-x86_64/spatial_cli.inc", "result": "PASS", "signature": "neboc geometry-check tests/rf204/G042/cases/valid.geometry", "stdout_bytes": 201, "stdout_sha256": "ba99e483177b99dccfb05316cacc9813b4214345d69316ad84d1bcab3bc31b50", "stdout_text": "geometry-check v1\nformat=NEBO-GEOMETRY-V1\nprecision=exact\ncrs=LOCAL-CARTESIAN-V1\nunits=millimetre\nsyntax=VALID\ntopology=NOT_EVALUATED\ngeometry=POLYGON((0 0,8 0,8 5,0 0))\nrepair=NOT_APPLIED\nmutation=NO\n"}

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Local bounded geometry/GIS; no external maps or global navigation assurance; original observation: valid document passes and incomplete document fails; SDK bounds: {"MAX_CODEC_BYTES":65536,"MAX_FACES":8192,"MAX_INDEX_ITEMS":4096,"MAX_POINTS":4096,"MAX_ROUTE_EDGES":8192,"MAX_ROUTE_NODES":2048}

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
    "boundary": "Bounded local document validation. Geometry topology is not evaluated; route-bench reports declared cases, not measured route timings.",
    "deterministic": true,
    "execution": "LOCAL_CLI_BOUNDARY",
    "identity": "owner:G042:G042-S07-07",
    "independent_oracle": "Exact validated user payload is reported; malformed versioned input rejects.",
    "input_context": {
      "argv": [
        "geometry-check",
        "tests/rf204/G042/cases/valid.geometry"
      ],
      "files": {
        "tests/rf204/G042/cases/valid.geometry": "NEBO-GEOMETRY-V1\nprecision=exact\ncrs=LOCAL-CARTESIAN-V1\nunits=millimetre\ngeometry=POLYGON((0 0,8 0,8 5,0 0))\n"
      }
    },
    "owner": "compiler/driver/cli/linux-x86_64/spatial_cli.inc",
    "result": "PASS",
    "signature": "neboc geometry-check tests/rf204/G042/cases/valid.geometry",
    "stdout_bytes": 201,
    "stdout_sha256": "ba99e483177b99dccfb05316cacc9813b4214345d69316ad84d1bcab3bc31b50",
    "stdout_text": "geometry-check v1\nformat=NEBO-GEOMETRY-V1\nprecision=exact\ncrs=LOCAL-CARTESIAN-V1\nunits=millimetre\nsyntax=VALID\ntopology=NOT_EVALUATED\ngeometry=POLYGON((0 0,8 0,8 5,0 0))\nrepair=NOT_APPLIED\nmutation=NO\n"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/driver/cli/linux-x86_64/spatial_cli.inc — SHA-256 e0f708b43e2e2bc9dd2f50147f71e515187874906eec54c23bbcc85e18c76127

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
