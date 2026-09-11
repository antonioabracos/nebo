# Transactional SDK upgrade and rollback

`nebo-offline upgrade ROOT` uses the same input options as restore. It stages a
complete new generation; it never updates the old generation in place. Before
materialization, a conservative compatibility precheck requires the same SDK
profile/version and the same frozen prelude, API/ABI and version documents.
The package root, entry, target, Edition, features, graph and module order stay
identical. Package pins may increase within the same major only when the full
native interface metadata/fingerprints and serialized interface hashes agree.
Breaking changes and unexplained drift require an independently prepared
migration; this bounded lifecycle refuses them. A major version bump is not a
substitute for compatibility evidence. No project public version is changed by
this tool.

Migration here means re-materializing the exact candidate manifests, sources,
lock and interfaces into the private candidate project. It executes no user
migration hook and edits no original workspace. The installed candidate compiler
rebuilds that project before activation. Inputs remain available unchanged.

The single selector replacement sets `active=candidate, previous=old-active`.
The old SDK, old project, old lock and old cache stay reachable as one rollback
point. The previous point from an earlier upgrade becomes unreachable and can
be collected after complete ownership validation. Identical candidates are
rejected; an already completed inactive generation may be reused only when its
entire manifest and payload agree.

`nebo-offline rollback ROOT` verifies the retained generation and cache, rebuilds
using the retained SDK and compares every restored project byte/mode before
atomically selecting the old generation. It clears `previous`; the abandoned
candidate is eligible for GC. Tests independently execute the old, candidate
and restored ELF and compare source/lock/SDK inventories. A corrupt active
candidate need not prevent rollback to a fully verified previous generation.
Failure to verify or rebuild the old point leaves the selector unchanged.

Writers use a nonblocking directory flock shared by restore, verify, repair,
upgrade, rollback, GC and uninstall. Contention rejects; the kernel releases the
lock on process death. Cooperative readers must hold the same lock for a long
operation spanning generation resolution and use. Direct external readers are
responsible for retaining their generation against concurrent GC.

Ordinary exceptions clean private stages. SIGTERM is translated to an exception
by both CLIs. SIGKILL before publication can leave an inactive private stage;
it cannot select a partially built generation. Such stages are reported and
preserved, never deleted by a filename glob. The owner may inspect and explicitly
remove its own interrupted stage. An interruption after generation publication
but before selection leaves a complete unreachable generation, recoverable by
retry or GC. No claim is made about arbitrary hardware/storage failure or
malicious concurrent writers with the same UID.

The older `nebo-sdk-lifecycle upgrade/rollback` commands now use Linux
`renameat2(RENAME_EXCHANGE)` so the active SDK pathname is continuously present.
They apply the same frozen SDK contract precheck and preserve the old install
profile. Those commands manage the SDK alone; use `nebo-offline` to transact SDK,
project and package/cache references together.
