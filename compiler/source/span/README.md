# SourceSpan v0

```txt
SourceId:
non-zero and typed by the caller

StartByte:
0-based inclusive

EndByteExclusive:
0-based exclusive

Invariants:
StartByte <= EndByteExclusive <= SourceLength

Empty spans:
valid

Union:
checked; both spans must belong to the same SourceId and SourceLength
```

A `SourceSpan` stores byte offsets, never raw pointers.
