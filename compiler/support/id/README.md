# Typed internal IDs v0

```txt
Physical type:
u64

Invalid sentinel:
0

Bits 63..56:
kind tag

Bits 55..0:
deterministic ordinal starting at 1

Kinds:
1 = StringId
2 = IdentifierId
```

An ID never contains, truncates, hashes or orders by a pointer. Two pools with
different addresses produce the same IDs when they intern the same sequence
under the same kind.
