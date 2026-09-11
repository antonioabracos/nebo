# import no grant

Import and prelude resolution grant no capabilities and execute no user initializer.

```text
Identity: N1-import-no-grant (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-import-no-grant — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Import and prelude resolution grant no capabilities and execute no user initializer.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### module-graph:pure-dag-17; expected 17

```nebo
module app;
import "project.worker".worker;
start worker.token;

```

Oracle: {"independent_builds": 2, "process_exit": 17, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

Provider worker.no

```nebo
module worker;
import "project.config".config;
export public token = 17;

```

Provider config.no

```nebo
module config;
export public limit = 83;

```

## Additional observations and limits

```text
[
  {
    "case_id": "metadata:prelude-declarations",
    "category": "metadata",
    "declarations": 11,
    "interface_sha256": "910170b1ccabf964a1186892ee9f4395f1b52c1e6b5cc7683f68ee2904de0933",
    "symbol_ids": [
      "0xb479812d2b532b1f",
      "0xa827441931b3ac13",
      "0x4f5f6793880ecdcc",
      "0x6134016fa73ad75e",
      "0xbbaa81a7272b4f17",
      "0x334a76a70563dd44",
      "0x34c249cdf79d7ac9",
      "0xaf1313c7a67a4790",
      "0xbd6f63ce5a3969ee",
      "0xe388cf778a8af553",
      "0x1c582e96c672743f"
    ]
  },
  {
    "case_id": "metadata:stdlib-profile",
    "category": "metadata",
    "exports": 20,
    "imports_grant_capabilities": false,
    "modules": 8,
    "physical_device_accessed": false,
    "registry_sha256": "a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922"
  }
]
```

## Related entries

[Index](index.md)

- [rule-call-order](rule-call-order.md)

- [rule-inference-and-binding](rule-inference-and-binding.md)

- [rule-overload-ranking](rule-overload-ranking.md)

- [rule-match](rule-match.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
