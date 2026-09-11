# Offline resolution and publication

The sole resolution authority is the directory passed as `--store`. Freeze
reads only explicit member manifests and declared sources under the selected
workspace. Restore reads only lock-declared files in that store. There is no
registry lookup, HTTP client, download, archive extraction, fallback store,
implicit current-directory search, build hook or source-provided executable.
Archives are outside this directory-store profile and rejected as non-directories.

Relative paths reject parent traversal, empty/dot components, absolute forms,
backslashes, drive/URL colons and NULs. Descriptor-relative `openat` operations
use `O_NOFOLLOW` on every input component. Files must be bounded regular files
with a single hard link; symlinks, FIFOs, devices and sockets are rejected.
The surrounding root directories are explicitly selected by the caller; as
with other local build tools, the caller must control these publication roots.

Freeze authenticates and compiles a private snapshot of all source inputs before
publishing a complete store. Restore authenticates content and native interfaces
before publishing a new project. Build additionally compiles a static ELF in the
private project and records its hash. Existing destinations are never replaced;
Linux `renameat2(RENAME_NOREPLACE)` makes the final directory publication atomic,
including concurrent destination creation. Failure removes this operation's
scratch and leaves the requested destination absent or its prior contents intact.
The commands do not run the generated application. G180 tests run it separately
under the existing bounded no-network runtime sandbox with an independent oracle.

Example invocation, with paths and pin supplied by the local caller:

```sh
build/bin/neboc package freeze workspace.json --store local-store
build/bin/neboc package verify --store local-store --lock local-store/nebo.lock.json --lock-sha256 <freeze-reported-sha256>
build/bin/neboc package restore --store local-store --lock local-store/nebo.lock.json --lock-sha256 <freeze-reported-sha256> --output clean-project
build/bin/neboc package build --store local-store --lock local-store/nebo.lock.json --lock-sha256 <freeze-reported-sha256> --output clean-build
```

Each native command is bounded to 20 seconds; input graphs have exactly three
native modules, at most three packages and two dependencies per package. The
G180 validator has a 600-second total deadline, individual command/runtime
deadlines, output limits and isolated generated inputs. Tests create no ZIP,
release package or repository copy and perform no network calls.
