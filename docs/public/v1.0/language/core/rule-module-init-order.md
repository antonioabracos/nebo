# module init order

The native module graph orders dependencies before consumers and lists each module once, independently of unit argument order. The admitted pure source/interface profile has zero runtime user initializers. Native initializer/rollback tests supplement this boundary without granting effectful imported startup.

```text
Identity: N1-module-init-order (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Syntax or signature

```text
N1-module-init-order — NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Scope and constraints

The native module graph orders dependencies before consumers and lists each module once, independently of unit argument order. The admitted pure source/interface profile has zero runtime user initializers. Native initializer/rollback tests supplement this boundary without granting effectful imported startup.

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
    "case_id": "module-graph:native-init-rollback",
    "observed_sha256": "85b7348d99e5f996dc1f73f80cd3fd997f2bf1040b1dd6357f581d5d19105773"
  }
]
```

## Related entries

[Index](index.md)

- [rule-call-order](rule-call-order.md)

- [rule-inference-and-binding](rule-inference-and-binding.md)

- [rule-overload-ranking](rule-overload-ranking.md)

- [rule-import-no-grant](rule-import-no-grant.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
