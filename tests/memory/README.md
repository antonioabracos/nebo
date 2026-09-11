# MF007 memory tests

```txt
mf007_memory_test.asm
→ scenarios 1, 2, 3, 6 and 8 through FakeHost

linux_memory_smoke.asm
→ real Linux HostServices reserve/release smoke
```

The numbered scenarios correspond to the approved Test ID suffixes:

| Scenario | Test ID |
|---:|---|
| `1` | `NEBO-MEM-UNIT_ASM-001` |
| `2` | `NEBO-MEM-NEG-002` |
| `3` | `NEBO-MEM-UNIT_ASM-003` |
| `6` | `NEBO-MEM-UNIT_ASM-006` |
| `8` | `NEBO-MEM-SECURITY-008` |

## MF008 collection support

```txt
mf008_collections_test.asm
→ scenario 4: deterministic growth and preserved content
→ scenario 5: overflow and failed-mutation safety
```

| Scenario | Test ID |
|---:|---|
| `4` | `NEBO-MEM-UNIT_ASM-004` |
| `5` | `NEBO-MEM-NEG-005` |

Slice, Buffer and TypedArray are internal support primitives. Language-level
List/Map collections remain outside this front.
