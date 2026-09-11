# diagnostic options

The public check command forwards bounded --max-errors (1..64), exclusive --fail-fast/--keep-going, human/short --show-fixes and --path-style relative/workspace/absolute to the native diagnostic owner. Duplicated options, incompatible modes and out-of-range arguments reject as usage errors before artifact publication.

```text
Identity: N1-diagnostic-options (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-diagnostic-options — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

The public check command forwards bounded --max-errors (1..64), exclusive --fail-fast/--keep-going, human/short --show-fixes and --path-style relative/workspace/absolute to the native diagnostic owner. Duplicated options, incompatible modes and out-of-range arguments reject as usage errors before artifact publication.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### cli:unchanged-no-option-runtime; expected 23

```nebo
start(){(17+6).return;}
```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### cli:default; expected NEBO_NAME_UNDEFINED

```nebo
start(){Int.x;absent.x;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_NAME_UNDEFINED"}

## Additional observations and limits

```text
[
  {
    "case_id": "cli:build-option-0",
    "category": "negative",
    "exit": 2,
    "observed_sha256": "80df32ecedd07d3781243cfc2da8c7c4971d459a9f40572cd8cde258fbd5877f"
  },
  {
    "case_id": "cli:build-option-1",
    "category": "negative",
    "exit": 2,
    "observed_sha256": "80df32ecedd07d3781243cfc2da8c7c4971d459a9f40572cd8cde258fbd5877f"
  },
  {
    "case_id": "cli:build-option-2",
    "category": "negative",
    "exit": 2,
    "observed_sha256": "80df32ecedd07d3781243cfc2da8c7c4971d459a9f40572cd8cde258fbd5877f"
  }
]
```

## Related entries

[Index](index.md)

- [rule-allocation-budget](rule-allocation-budget.md)

- [rule-arithmetic-failures](rule-arithmetic-failures.md)

- [rule-output-capacity](rule-output-capacity.md)

- [rule-recursion-budget](rule-recursion-budget.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- compiler/driver/cli/linux-x86_64/cli_driver.asm — SHA-256 0005784201af6835cb78990bd7f0800aa5b745fb813a6bd744934254766560ed

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
