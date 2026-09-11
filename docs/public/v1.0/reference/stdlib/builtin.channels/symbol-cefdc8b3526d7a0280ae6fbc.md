# builtin.channels — Channel.unbuffered

No-peer try operations report unavailable transfer; no successful rendezvous is claimed.

```text
Identity: material:Channel.unbuffered (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: MATERIAL_BOUNDED_NOT_PROMOTED
```

## Syntax or signature

```text
Channel<Int>.unbuffered() -> Channel<Int>
```

## Bounded behavior

No-peer try operations report unavailable transfer; no successful rendezvous is claimed. Int64 FIFO capacity 1..64; unbuffered no-peer; closed/empty/full/wait error codes; independent token state

## Lifecycle, safety and determinism

Int64 FIFO capacity 1..64; unbuffered no-peer; closed/empty/full/wait error codes; independent token state. Failures retain previous private files and do not grant network or device access. Cooperative execution is not proof of OS-thread race freedom.

## Availability

MATERIAL_BOUNDED_NOT_PROMOTED. This individual member retains its owning profile maturity. Only x86_64-systemv-elf-linux is observed.

## Executed examples

### system:channel-rendezvous-no-peer; expected 23

```nebo
start(){Channel<Int>.unbuffered().c;c.trySend(17).getErr().console();c.tryReceive().getErr().console();c.close();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "1011", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4, 4\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "14ee496083995ee8bbb8a19e51f3a76993230b7c0d3e305841b3817a8077bab6", "text": {"bytes_hex": "31303131"}}

## Rejected examples

### system:channel-capacity-over; expected NEBO_LIMIT_EXCEEDED

```nebo
start(){Channel<Int>.bounded(65).c;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_LIMIT_EXCEEDED"}

## Related entries

[Index](index.md)

- [symbol-32dff80ce6d51967c19cd1e0](symbol-32dff80ce6d51967c19cd1e0.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-PROFILE-BOUNDARIES.tsv — SHA-256 f75432d694f4cdd8f47bc28f34f8d031ba92fdf5147cd157161356c9832036e3

- runtime/concurrency/channel.asm — SHA-256 4f6573cb04d05baed91b038b25480bb548985adace3df5bfd38dadf72668464d

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/random_test.py — SHA-256 a4d3692d30d6947812089d0ad64318a32a6a9279c567ac96481f207daeb95516
