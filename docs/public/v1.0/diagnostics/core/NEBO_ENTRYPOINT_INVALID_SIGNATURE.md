# NEBO_ENTRYPOINT_INVALID_SIGNATURE

start() violates the frozen entrypoint signature or status contract

```text
Identity: NEBO_ENTRYPOINT_INVALID_SIGNATURE (DIAGNOSTIC_CODE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: NATIVE_DEFINITION_AND_SOURCE_REJECTION
```

## Syntax or signature

```text
Code: NEBO_ENTRYPOINT_INVALID_SIGNATURE
Severity: 1
Phase: 6
Message: start() violates the frozen entrypoint signature or status contract
```

## Meaning and remediation

Condition reported: start() violates the frozen entrypoint signature or status contract. Locate the primary span, correct this condition and re-run check before requesting build. For capacity diagnostics reduce the indicated bounded input; for type/receiver errors use the declared domain; for internal invariant failures retain the source and compiler identity for a compiler defect report.

## Exit and span contract

source error=1; usage/environment=2; internal=101; success=0. UTF8 byte half-open; LSP UTF16 conversion. JSON-lines schema 1; SARIF 2.1.0 properties.neboSchema=1; LSP data.schema=1.

## Reachability

The source rejection below actually produced this code.

## Compatibility

Code not reused; severity phase span encoding and field types frozen; message interpolation values may vary

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Rejected examples

### slash:status-type; expected NEBO_ENTRYPOINT_INVALID_SIGNATURE

```nebo
start(){RenderPlan("a").return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_ENTRYPOINT_INVALID_SIGNATURE"}

## Additional observations and limits

```text
[
  {
    "case_id": "compatibility-native:diagnostic-catalog",
    "category": "diagnostics",
    "entries": 182,
    "observed_sha256": "1b50f16a6574fd034d687a5717f90611d568cf5c5eee33bc2a7e1e03d828148d"
  }
]
```

## Related entries

[Index](index.md)

- [NEBO_CLI_USAGE](NEBO_CLI_USAGE.md)

- [NEBO_SOURCE_BOM_FORBIDDEN](NEBO_SOURCE_BOM_FORBIDDEN.md)

- [NEBO_SOURCE_TOO_LARGE](NEBO_SOURCE_TOO_LARGE.md)

- [NEBO_LEX_INVALID_UTF8](NEBO_LEX_INVALID_UTF8.md)

## Provenance

- compiler/diagnostics/catalog.asm — SHA-256 bba36decf36e5dd598885f3edcdf1234885b5115e30b6392e8a5b2e746231af2

- compiler/diagnostics/diagnostic.inc — SHA-256 6673fbb09ad4b3a3490ddb849bf6f1cda7bcd445f428395bdf14dc359318e8ae

- tests/rf204/G170/slash_test.py — SHA-256 f25f3e8878b8e7a0281d721f375c25eb5653cccfc146868ec7db4d447400b1c4

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
