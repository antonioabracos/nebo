# Deterministic hashing v0

```txt
Algorithm:
FNV-1a 32-bit

Offset basis:
2166136261

Prime:
16777619

Seed:
fixed by the algorithm; no random seed

Equality:
hash + length + complete byte comparison

Security role:
none — this is a deterministic compiler-internal lookup accelerator
```

A hash match is never treated as string equality by itself. The StringPool
compares the complete byte sequence, so true hash collisions remain correct.
