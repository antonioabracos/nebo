# Build Nebo 1.1.0 from source

Language Edition: 1.0. Status: FINAL_RELEASE.
Latest published release: 1.1.0.
Release date: 2026-09-12
Release timestamp (UTC): 2026-09-12T07:14:22Z
Tag: nebo-v1.1.0
Publication channel: GitHub Release; publication authorization: RELEASE_GO.

On Linux x86-64 with Python 3, Ninja, NASM and GNU binutils installed:

```sh
./scripts/build-neboc.sh
build/bin/neboc --version
bash scripts/ci-public.sh
```

The compiler and runtime use Assembly and produce static ELF64 executables.
Builds and tests do not download dependencies. The CI entry point checks the
public path policy, version, examples, indexing, collections, data/streams,
documentation and offline SDK lifecycle. SDK installation uses a temporary
user-owned prefix. See [README.md](README.md) and the
[migration guide](docs/releases/NEBO-1.1.0-MIGRATION-GUIDE.md).

The CI entry point selects the system tools in `/usr/bin:/bin` and disables
Python and loader overrides, matching the environment of the isolated SDK
rebuild. Install the distribution's Python Pillow package for that gate.

Collection construction, capacity, access and mutation validators derive the
source root from their own location and place any Python cache under the
ignored build directory. They can be invoked from another working directory.
An optional `NEBO_REPO_ROOT` selects another existing source checkout; empty or
invalid roots fail with a diagnostic before a build starts.

The public privacy gate scans explicit nonempty file inventories and archive
members, fails on unreadable inputs, and tests synthetic home paths, internal
execution metadata and safe public CLI/loopback tokens. It does not print
matched credential bytes.
