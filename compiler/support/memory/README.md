# Memory foundation — MF007

## Layering

```txt
HostServices memory reserve/release
→ MemoryRegion v0
→ Arena v0
→ checked bump allocation
→ future typed collections
```

## MemoryRegion v0

```txt
Physical size: 80 bytes
Ownership: one non-zero owner token
Generation: changes on each init/destroy lifecycle
Reservation: contiguous and owned until destroy succeeds
Committed bytes: equal to reserved bytes in v0
Growth: not implemented
```

## Arena v0

```txt
Physical size: 112 bytes
Region ownership: borrowed
Individual free: absent
General allocator: absent
GC: absent
Maximum alignment: 4096 bytes
Zero-size allocation: deterministic aligned pointer; no cursor advance
Mutations: exact owner token required
```

Operations:

```txt
neboc_arena_init
neboc_arena_validate
neboc_arena_allocate
neboc_arena_allocate_zeroed
neboc_arena_align
neboc_arena_mark
neboc_arena_rewind
neboc_arena_reset
neboc_arena_destroy
```

`arena_reset` changes the arena generation. A mark or MemorySpan carrying an
older generation is rejected with `NEBOC_STATUS_INVALID_ARGUMENT`.

## Preliminary limits

```txt
Default region reservation: 1 MiB
Default region maximum: 64 MiB
Hard region maximum: 1 GiB
Compiler source/session limit from DG-009: 16 MiB
```

The first implementation reserves one contiguous region. Commit-on-demand and
region growth are deferred; limits cannot be raised merely to hide a failure.

## MF007 bounds seam

`MemorySpan` is a minimal read-only test seam for the approved MF007 bounds
Test ID. The complete Slice representation and API remain strictly deferred to
MF008.
