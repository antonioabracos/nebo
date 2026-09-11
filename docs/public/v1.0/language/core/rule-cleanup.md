# cleanup

Success, early return and allocation failure release all live resources exactly once.

```text
Identity: N1-cleanup (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-cleanup — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Success, early return and allocation failure release all live resources exactly once.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### ownership:implicit-drop; expected 23

```nebo
start(){Allocator.system().a;a.allocate(43).b;23.return;}
```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "0566ec1360fdba532d0aff9673a5dcb1cbb720f6a5a886753f18df52509f7fa6"}

## Rejected examples

### ownership:double-drop; expected NEBO-OWNERSHIP-DOUBLE-DROP

```nebo
start() {
    "drop".owner;
    owner.drop().first;
    owner.drop().second;
    0;
}

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-OWNERSHIP-DOUBLE-DROP"}

## Related entries

[Index](index.md)

- [rule-move](rule-move.md)

- [rule-copy-clone](rule-copy-clone.md)

- [rule-borrow-aliasing](rule-borrow-aliasing.md)

- [rule-lifetime-escape](rule-lifetime-escape.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/ownership_test.py — SHA-256 ed4f10840cdff23e8f7f520c0603208b18e27f2b31c346846bd9e805a2516e4d

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
