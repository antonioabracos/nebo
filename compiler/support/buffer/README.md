# Buffer v0

```txt
Physical size: 80 bytes
Growth: deterministic doubling from capacity 8
Maximum backing bytes: 1 GiB
Append: checked typed element count
Finalize: immutable checked Slice
Individual release: absent
```

Growth allocates a new block from the same Arena and copies the live content.
The previous block remains owned by the Arena until reset or destroy.
