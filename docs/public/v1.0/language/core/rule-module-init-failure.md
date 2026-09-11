# module init failure

Cycles and effectful imported startup reject before publication. Native rollback reverses successfully initialized resources in the internal initialization contract; interface loading executes no user code.

```text
Identity: N1-module-init-failure (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Syntax or signature

```text
N1-module-init-failure — NORMATIVE_BOUNDARY_WITH_INTERNAL_SUPPLEMENT
```

## Scope and constraints

Cycles and effectful imported startup reject before publication. Native rollback reverses successfully initialized resources in the internal initialization contract; interface loading executes no user code.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### source:S04; expected 47

```nebo
// The harness supplies module values with the public Int constant token=47.
// The same consumer executes after the provider is replaced by its binary .ni.
doc {
 title: "Normative module consumer";
 summary: "Read a material imported constant without running an initializer.";
 effects { pure; }
 capabilities { none; }
 example "exit-47" { start(){47.return;} }
 law "law-exit-71" { start(){71.return;} }
}
module app;
import "project.core".values;
start values.token;

```

Oracle: {"independent_builds": 2, "process_exit": 47, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

Provider core.no

```nebo
module core;
export public token = 47;

```

Provider util.no

```nebo
module util;
export public delta = 7;

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
