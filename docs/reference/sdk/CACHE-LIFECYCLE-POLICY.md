# Local cache lifecycle policy

The offline root owns an immutable cache keyed by the canonical G180 lock's
`cache_key`. Each entry includes the canonical lock and all exact package files,
including native interfaces. Inputs to the key include source, manifest,
interface, target, Edition, features, graph and compiler/toolchain provenance.
A cache hit revalidates all bytes; a stale or corrupt entry is a failure, not a
hit. There is no implicit network retry and no cloud cache.

`nebo-offline gc ROOT` derives reachability exclusively from the authenticated
active and previous generation records. It validates every generation and cache
candidate, complete file sets, live lock references and resource limits before
any deletion. It preserves both active and rollback locks and their cache
entries. Only unreachable owned entries are removed. Unknown files, symbolic
links, hardlinks, bad hashes and stale toolchains cause rejection and preserve
the offending data for diagnosis. Empty foreign directories also count as
foreign data. GC does not guess ownership from an alphanumeric name.

Limits: eight retained generations, 32 cache entries, SDK manifests/payloads
within the G193/G194 file and byte budgets, JSON records at most 16 MiB, lowercase
64-character keys, and G180's package/module/source limits. Call GC before
exceeding the retention budget. The legacy low-level `sdk_lifecycle.cache_gc`
validates every entry before deletion; callers of that helper must supply a
complete active set. The public combined lifecycle derives it itself.

Package file modes are normalized to 0644 and generated executables to 0755.
Restore identity is independent of the caller's umask and filesystem enumeration
order. Tests compare manifests, native ELF bytes, exit values, lock bytes and
project inventories across cold/warm paths and relocated roots. Runtime values
come from two independent imported Nebo dependencies per principal example.

Uninstall preflights owned content, atomically deactivates the selection and
collects the owned generations and cache. It rejects foreign data and leaves
unrelated input stores, original projects and SDK inputs unchanged. It does not
remove system state. Eviction/uninstall are resumable local deletion operations;
no multi-file deletion transaction or power-loss atomic deletion is claimed.
