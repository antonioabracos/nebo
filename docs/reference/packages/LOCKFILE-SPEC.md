# Deterministic package lock and cache identity

`nebo.lock.json`, schema `NEBO-PACKAGE-LOCK-v2`, is canonical UTF-8 JSON with
exact fields: `schema`, `root`, `entry`, `edition`, `target`, `features`,
`toolchain`, `packages`, `package_order`, `module_order`, `cache_key`.
No absolute workspace path, timestamp or observed process status enters the lock.

Packages are sorted by PackageId. Every row contains `id`, exact `version`,
`content_sha256`, `files`, `interfaces`, and sorted `dependencies`. `files`
maps the canonical manifest, declared `.no` sources and generated `.ni` paths
to SHA256. `content_sha256` hashes the canonical file-hash map. The immutable
store path is `packages/<PackageId>/<version>/<content_sha256>/<file>`.
Each graph has one root and all packages must be reachable.

`interfaces` is indexed by logical module. It records native ModuleId, API,
ABI, behavior and typed-HIR fingerprints, material exported value, export count,
and the interface's SHA256. These facts come from the native `.ni` codec;
the Python package layer does not invent interface encodings. On restore the
source graph is checked again, its interfaces regenerated, and all facts and
bytes compared. All-zero placeholders and coherently rehashed stale interfaces
therefore cannot provide successful verification.

`toolchain` pins the executable compiler, native interface codec, runtime object,
local compiler SDK/host consumers, prelude/stdlib inputs, G177/G178 catalog
manifests and external host tools. These are local content identities, not a
claim of source bootstrap or a release signature. Toolchain changes require a
fresh freeze; a stale cache is rejected. Catalog fingerprints bind the current
module boundary but do not promote target-gated APIs or grant capabilities.

`cache_key` is SHA256 of canonical lock content excluding the key itself. Thus
it includes source, interface, package identity/version, toolchain, target,
edition, features, dependencies and build/init order. The store itself is the
content-addressed artifact cache; there is no second unverified executable cache.
A rebuild uses authenticated source or `.ni` inputs and the pinned local toolchain.

The caller supplies a trusted `--lock-sha256` for verify, restore and build.
The lock is pinned before resolving paths. A pin is an integrity reference,
not proof of author identity; there are no signing keys or remote trust claims.
Unknown schema/fields, reordered noncanonical package arrays, duplicate identities,
unresolved pins, extra file declarations and inconsistent graphs fail closed.
