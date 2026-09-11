# Installation and targets

This repository's verified compiler is `build/bin/neboc`, produced locally with
the checked-in Ninja graph. The tested environment is Linux x86-64 using the
System V ABI and static ELF output.

```bash
ninja -j1 neboc
build/bin/neboc --version
file build/bin/neboc
readelf -lW build/bin/neboc
```

Historical RC packages and tags remain immutable local evidence. The canonical
compiler version is `1.1.0`; the bounded pre-publication bridge owns the source
and SDK archives. No registry download, second supported target, remote or
publication is implied.

## Offline maintenance

The repository and installed SDK/tooling distributions provide
`python3 -B tools/nebo-offline.py` with `init`, `restore`, `verify`, `upgrade`,
`rollback`, `repair`, `gc` and `uninstall`. An explicit owned root and caller-pinned
SDK manifest, package lock and local store are required. The active generation
selects the SDK, project, lock and cache together. Compatible updates preserve
the previous complete generation; GC derives reachability from both live locks.

See [offline restore](../reference/sdk/OFFLINE-RESTORE-SPEC.md),
[upgrade and rollback](../reference/sdk/SDK-UPGRADE-ROLLBACK-SPEC.md), and
[cache policy](../reference/sdk/CACHE-LIFECYCLE-POLICY.md) for schemas, commands,
resource limits, recovery and concurrency boundaries. This is a local integrity
workflow; pending external release gates remain pending.
