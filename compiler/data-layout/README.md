# DataLayout v0

MF031 freezes the first target data layout for `x86_64-systemv-elf-linux`.

The record is pointer-free except for its owner in `TargetContext`, is frozen after
initialization, and encodes 64-bit pointers/Int/handles, `0/1` Bool, pointer+length
slices, 16-byte stack alignment and little-endian byte order.

`neboc_data_layout_validate` recomputes FNV-1a over the 136 canonical bytes and
rejects zero or mismatched stored hashes without mutating the frozen record.

No second target, physical register allocation, object writer or backend is present.
