# Slice v0

```txt
Physical size: 48 bytes
Fields: pointer, length, element size, Arena, generation, owner
Ownership: borrowed
Bounds: checked
Stale Arena generation: rejected
Individual release: absent
```

A Slice is a typed view over memory already allocated from an Arena. It cannot
outlive the Arena generation captured at initialization.
