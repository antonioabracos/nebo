# borrow aliasing

Shared/unique views constrain mutation, reset, drop and move until release.

```text
Identity: N1-borrow-aliasing (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-borrow-aliasing — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Shared/unique views constrain mutation, reset, drop and move until release.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### ownership:G004-02; expected 23

```nebo
// Shared borrows may coexist and derive shorter read-only views. A unique
// borrow is exclusive and may update the owner before an explicit release.
start() {
    "borrowed text".owner;
    owner.borrowShared().immutableBorrow;
    immutableBorrow.scope().lexicalScope;
    immutableBorrow.reborrow().shortBorrow;
    immutableBorrow.asSlice().byteView;
    shortBorrow.release().shortReleased;
    byteView.release().viewReleased;
    immutableBorrow.release().immutableReleased;

    7.mutableOwner;
    mutableOwner.borrowUnique().mutableBorrow;
    mutableBorrow.write(23).written;
    mutableBorrow.read().observed;
    mutableBorrow.release().mutableReleased;
    observed;
}

```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### ownership:unique-reborrow-conflict; expected NEBO-BORROW-MUTABLE-CONFLICT

```nebo
start() {
    7.owner;
    owner.borrowUnique().unique;
    unique.reborrow().conflict;
    0;
}

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-BORROW-MUTABLE-CONFLICT"}

## Related entries

[Index](index.md)

- [rule-move](rule-move.md)

- [rule-copy-clone](rule-copy-clone.md)

- [rule-lifetime-escape](rule-lifetime-escape.md)

- [rule-cleanup](rule-cleanup.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/ownership_test.py — SHA-256 ed4f10840cdff23e8f7f520c0603208b18e27f2b31c346846bd9e805a2516e4d

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
