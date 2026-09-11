# builtin.sync — AtomicInt

The AtomicInt receiver/type supports the individually listed operations under the same bounded ownership and target profile. Use the executed construction form below.

```text
Identity: material-type:AtomicInt (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: MATERIAL_BOUNDED_NOT_PROMOTED
```

## Syntax or signature

```text
AtomicInt — material receiver/type profile
```

## Bounded behavior

The AtomicInt receiver/type supports the individually listed operations under the same bounded ownership and target profile. Use the executed construction form below. Typed Int payloads; guard release across scope/return/break/continue; compareExchange; unique ownership and no escape

## Lifecycle, safety and determinism

Typed Int payloads; guard release across scope/return/break/continue; compareExchange; unique ownership and no escape. Failures retain previous private files and do not grant network or device access. Cooperative execution is not proof of OS-thread race freedom.

## Availability

MATERIAL_BOUNDED_NOT_PROMOTED. This individual member retains its owning profile maturity. Only x86_64-systemv-elf-linux is observed.

## Executed examples

### sync:atomic-17; expected 23

```nebo
start(){AtomicInt.new(17).a;a.load(4).console();a.store(53,4);a.compareExchange(53,17,4).yes;yes.swapped().console();yes.observed().console();a.compareExchange(53,7,4).no;no.swapped().console();no.observed().console();a.fetchAdd(11,4).console();a.load(4).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "17true53false171728", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4, 5, 4, 5, 4, 4, 4\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "7fc6443de03949034a1388df389a3e169d16100d53e266273261d6de9858777b", "text": {"bytes_hex": "313774727565353366616c7365313731373238"}}

## Rejected examples

### sync:sync-negative-atomic-type; expected NEBO_TYPE_MISMATCH

```nebo
start(){AtomicInt.new(true).a;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-985d69803309d18f33e34dde](symbol-985d69803309d18f33e34dde.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-PROFILE-BOUNDARIES.tsv — SHA-256 f75432d694f4cdd8f47bc28f34f8d031ba92fdf5147cd157161356c9832036e3

- runtime/concurrency/sync_public.asm — SHA-256 49b93b3e68282dcc9a6cbb37e4a363400d87d58bf7fabaf9e8b99ceb2f9bc7b7

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
