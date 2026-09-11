# builtin.tasks — TaskGroup

The TaskGroup receiver/type supports the individually listed operations under the same bounded ownership and target profile. Use the executed construction form below.

```text
Identity: material-type:TaskGroup (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: MATERIAL_BOUNDED_NOT_PROMOTED
```

## Syntax or signature

```text
TaskGroup — material receiver/type profile
```

## Bounded behavior

The TaskGroup receiver/type supports the individually listed operations under the same bounded ownership and target profile. Use the executed construction form below. Noncapturing Int callback; cooperative deterministic admission; single-consumer Future; callback once; cancellation

## Lifecycle, safety and determinism

Noncapturing Int callback; cooperative deterministic admission; single-consumer Future; callback once; cancellation. Failures retain previous private files and do not grant network or device access. Cooperative execution is not proof of OS-thread race freedom.

## Availability

MATERIAL_BOUNDED_NOT_PROMOTED. This individual member retains its owning profile maturity. Only x86_64-systemv-elf-linux is observed.

## Executed examples

### tasks:task-map-17; expected 23

```nebo
(Int.index)work(){(index+17).return;}(Int.value)scale(){(value*3+7).return;}start(){TaskGroup.new().g;g.spawn(work).a;g.spawn(work).b;a.map(scale).c;c.await().get().console();b.await().get().console();g.joinAll().get().console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "58182", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4, 4, 4\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "e96f7f55443f9c167da067c7a24b02363a634f2fe64a31eac8c5969ba1858296", "text": {"bytes_hex": "3538313832"}}

## Rejected examples

### tasks:task-negative-missing-callback; expected NEBO_TYPE_MISMATCH

```nebo
start(){Task.spawn(absent);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-759704c15028d692ae743f04](symbol-759704c15028d692ae743f04.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-PROFILE-BOUNDARIES.tsv — SHA-256 f75432d694f4cdd8f47bc28f34f8d031ba92fdf5147cd157161356c9832036e3

- runtime/concurrency/task.asm — SHA-256 8998ad99a2f58f987b6ab933f931a01e0614c916584ba0c79db5ff489d43406b

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
