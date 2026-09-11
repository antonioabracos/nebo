# Packages and developer tooling

`tools/rf27-package.py` provides the bounded local package operations `init`,
`add`, `remove`, `resolve`, `audit`, `vendor` and `package`. Resolution is
offline and lockfile-based; package inputs are validated and extraction is
confined to the authorized destination. The formatter, REPL, LSP adapter, test
runner and doctor are local tools:

```bash
python3 tools/rf27-format.py --help
python3 tools/rf27-package.py --help
python3 tools/rf27-test.py --help
python3 tools/rf27-doctor.py
```

The doctor reports the actual four-file supply-chain inventory and local tool
availability. Its output is evidence, not a signature: the current policy has
no signing keys and makes no signature-verification claim.

The material exact-pin profile is exposed as `neboc package freeze`,
`neboc package verify`, `neboc package restore` and `neboc package build`.
It binds package identities and exact versions to source hashes, native `.ni`
interfaces, dependency/init order and the local toolchain. The initial native
profile has exactly three modules across one to three packages, with explicit
directory stores and no network or build hooks. A pinned lock is required for
restore/build, and existing destinations are never replaced.

See the [manifest specification](../reference/packages/PACKAGE-MANIFEST-SPEC.md),
[lock specification](../reference/packages/LOCKFILE-SPEC.md) and
[offline commands and policy](../reference/packages/OFFLINE-RESOLUTION-POLICY.md).
