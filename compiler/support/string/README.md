# StringPool v0

```txt
Equality:
hash + length + full byte comparison

Identifier profile:
ASCII only: [A-Za-z_][A-Za-z0-9_]*

Hash:
FNV-1a 32-bit with fixed algorithm constants

Lookup structure:
deterministic linear table

ID assignment:
(kind << 56) | insertion_ordinal

Invalid ID:
0

Individual string free:
absent

Pointer-based ID or ordering:
absent
```

The linear lookup is an explicitly approved deterministic fallback for v0. It
stores the hash to avoid most byte comparisons but never trusts a hash match
without comparing the complete string.
