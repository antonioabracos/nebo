# NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-CODEGEN-004

std.math code generation is unavailable before BIBLIOTECA-PADRAO-POR-DOMINIOS-PF005

```text
Identity: NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-CODEGEN-004 (DIAGNOSTIC_CODE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: NATIVE_DEFINITION_ONLY
```

## Syntax or signature

```text
Code: NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-CODEGEN-004
Severity: 1
Phase: 10
Message: std.math code generation is unavailable before BIBLIOTECA-PADRAO-POR-DOMINIOS-PF005
```

## Meaning and remediation

Condition reported: std.math code generation is unavailable before BIBLIOTECA-PADRAO-POR-DOMINIOS-PF005. Locate the primary span, correct this condition and re-run check before requesting build. For capacity diagnostics reduce the indicated bounded input; for type/receiver errors use the declared domain; for internal invariant failures retain the source and compiler identity for a compiler defect report.

## Exit and span contract

source error=1; usage/environment=2; internal=101; success=0. UTF8 byte half-open; LSP UTF16 conversion. JSON-lines schema 1; SARIF 2.1.0 properties.neboSchema=1; LSP data.schema=1.

## Reachability

This code definition is observed through the linked native catalog/registry probe. No public source trigger is claimed for this code in the measured profile. A catalog definition alone does not establish reachability.

## Compatibility

Code not reused; severity phase span encoding and field types frozen; message interpolation values may vary

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

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

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
