# console and scan

console() is the canonical output surface; print is not valid Nebo. Mock/stdin Scan follows its typed result, cancellation, bounds and redaction contracts. Headless/software evidence does not assert live desktop or hardware availability.

```text
Identity: N1-console-and-scan (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-console-and-scan — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

console() is the canonical output surface; print is not valid Nebo. Mock/stdin Scan follows its typed result, cancellation, bounds and redaction contracts. Headless/software evidence does not assert live desktop or hardware availability.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### console:color-implicit-standalone; expected 0

```nebo
start(){Color(17,29,53);}
```

Oracle: {"independent_builds": 2, "process_exit": 0, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### source:reject-print; expected NEBO_PARSE_UNEXPECTED_TOKEN

```nebo
start(){17.print();23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_PARSE_UNEXPECTED_TOKEN"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- sdk/contracts/stdlib/STDLIB-PROFILE-BOUNDARIES.tsv — SHA-256 f75432d694f4cdd8f47bc28f34f8d031ba92fdf5147cd157161356c9832036e3

- tests/rf204/G170/console_public_test.py — SHA-256 4ff1b67ea212ce82443057d944c9993e64ad919fe90faadb19f0cb6014f4cff5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
