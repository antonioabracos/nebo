# Executable projects

- `project`: a typed three-unit consumer and a re-exported Int; source/NI parity, status 94.
- `data`: a local UTF-8 file transformed through the bounded sorted-key JSON profile; exact canonical bytes and status 47.
- `concurrency`: a noncapturing task and bounded channel; observed values 73 and 89, status 61.
- `packages`: three exact-pinned local packages; freeze/verify/build without a registry, status 108.

Each project carries complete source and independent inputs/expected context. The interface-query unit enables emit-interface without a development-tree fixture. The package directory includes manifests, provider sources and CLI instructions. The documentation archive carries these same bytes; `tests/rf204/G188/validate.sh` executes the source, NI and package variants, including relocated installed consumers.
