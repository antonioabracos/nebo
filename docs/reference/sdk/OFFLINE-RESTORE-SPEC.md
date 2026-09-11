# Offline restore specification

The Linux x86-64 local consumer is `python3 -B tools/nebo-offline.py` in a
repository or installed `sdk`/`tooling` distribution. It requires an explicit
owned root, SDK input, SHA-256 of its `MANIFEST.json`, package store, canonical
G180 lock and SHA-256 of the lock. An archive additionally requires its own
SHA-256. Pins are supplied through a trusted local caller; they are integrity
checks, not signatures or external release acceptance.

```
python3 -B tools/nebo-offline.py init /owned/project-state
python3 -B tools/nebo-offline.py restore /owned/project-state \
  --sdk /owned/sdk-input --sdk-sha256 SDK_MANIFEST_SHA256 \
  --store /owned/package-store --lock /owned/package-store/nebo.lock.json \
  --lock-sha256 LOCK_SHA256
python3 -B tools/nebo-offline.py verify /owned/project-state
```

All paths are explicit. The root's existing parent must be owned by the caller
and have no group/world write permission. Root, store and SDK traversal rejects
symbolic links; component readers reject hardlinks, special files and excessive
sizes. No directories in the host profile, PATH, registry or system installation
are changed. There is no network discovery, downloader or fallback.
The compiler's package adapters start Python with `-BS`: standard-library and
explicit local imports work without site/user discovery or bytecode writes.
Nested adapter dispatch preserves those flags. This avoids implicit NSS/nscd
lookups even when the native runner deliberately supplies an empty environment.

`state.json` has exactly `schema`, `active`, `previous`; its schema is
`NEBO-OFFLINE-LIFECYCLE-v1`. Both references are null or lowercase SHA-256 keys.
The root contains `generations/` and `cache/`. A generation contains `sdk/`,
`project/`, `nebo.lock.json` and `generation.json`. Its key hashes canonical
`{schema,sdk_sha256,lock_sha256}`. The generation record additionally contains
the lock's cache key and a sorted inventory of sizes, hashes and modes. Records
contain no absolute paths, timestamps, local usernames or environment values.

An admitted SDK must be a complete G193 composition in the sdk/tooling profile,
with the current supported target. SDK payloads are copied through the G194
manifest owner. Exact packages, source files and `.ni` interfaces are copied
from the caller-pinned store. The staged SDK's Python host and native compiler
rebuild and revalidate the graph and native interface fingerprints. The existing
G180 bound is three logical modules in one to three packages; source is at most
4096 bytes per module. Unsupported features, targets, editions and stale
compiler/toolchain identities are rejected by that owner.

Activation selects the complete SDK, project, lock and cache reference with one
atomic replacement of `state.json`. Consumers read that selector once and use
`generations/<active>/sdk/bin/neboc` and `generations/<active>/project/bin/program`.
`verify` returns the selected keys; it recomputes payload integrity and verifies
both live cache references. Generation payloads and directories are synced
before publication. A selector fsync error restores its old bytes.

An invalid input returns exit 2, empty stdout and a structured stderr diagnostic.
`NEBO_OFFLINE_*`, `NEBO_PACKAGE_*` and `NEBO-SDK/INSTALL-*` identify the first
rejecting owner. Nested package build errors retain a bounded cause code. Raw
paths, file contents and compiler transcripts are not copied into CLI errors.
There is no source span for a filesystem/schema rejection; native source errors
are also tested directly at their compiler owner.

`repair` takes the same pins as restore and must reconstruct the active identity.
It repairs damaged cache/project/SDK bytes while preserving the selector. Unknown
paths, linked content or a different identity are rejected before replacement.
No best-effort repair masks the original verification error. `verify` must first
report corruption; tests then prove the repaired ELF, source and lock identity.
