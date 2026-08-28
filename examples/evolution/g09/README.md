# G09 programmer-defined types example

`../g09-programmer-defined-types.no` is the executable bounded product example. It validates with `neboc check`, emits deterministic NASM Assembly, builds a static x86-64 System V ELF, and exits with `3`.

The broader G09 conformance set also covers unit/payload sums, one `Scalar` parameter, and composition with `Option`, `Result`, and `PositiveInt`. Pattern matching, general ownership, visibility and FFI remain explicitly deferred.
