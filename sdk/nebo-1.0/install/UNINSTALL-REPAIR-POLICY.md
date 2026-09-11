# Ownership, uninstall, repair and local diagnostics

`uninstall PREFIX` validates the complete ownership manifest before deletion.
Only regular, singly linked files whose bytes, size and mode still match their
owned records are removed. Missing files are tolerated. Modified files, symlinks,
hardlinks, special files, user projects, configuration and package cache remain.
Only empty **owned parent directories** are pruned. Empty user directories are
preserved. The returned `removed`, `preserved` and `leftovers` lists describe the
result; `cache_policy` is `preserve-unowned`. Links are reported without following
them. Inventory is limited to 80,128 entries and 64 levels before mutation.
Uninstall is restartable up to removal of its manifest; it is not advertised as
one atomic deletion transaction. Preserve the local source archive for recovery.

`verify PREFIX` recalculates every owned SHA256, byte size and permission mode.
It does not modify the prefix and does not mistake user files for distribution
files. The install manifest is an ownership record, not a cryptographic trust
anchor against a user who can rewrite it and the entire prefix.

`repair LOCAL_SDK PREFIX`, or `repair LOCAL.tar PREFIX --archive-sha256 DIGEST`,
requires the complete original identity, including MANIFEST.json. It stages all
required local bytes before replacing missing, corrupt or mode-drifted components.
It holds the lifecycle lock, rejects linked/special destinations, verifies after
replacement, and rolls back previous replacements on an ordinary exception.
No component of a different version is silently adopted. Unowned configuration,
projects and cache are untouched. Mutated distribution assets are restored; keep
personal configuration outside manifest-owned paths. SIGKILL during repair may
leave a subset repaired and an inactive repair staging directory; every published
replacement is a complete file of the same authenticated version. Re-run repair.
This is not a claim of power-loss atomic multi-file repair.

`neboc doctor [--sdk-root PREFIX] [--output NEW_REPORT.json]` reports registered
checks for SDK integrity, native compiler, toolchain fingerprints, target, prefix
permissions, display configuration and optionally authenticated local packages.
The default root is the current installation. Exit 0 means required checks passed;
3 means degraded. Exit 2 reports invalid arguments or rejected output. Source and
docs-only profiles cannot claim an executable toolchain. Display configuration is
reported as unprobed; doctor never connects to a display or network. External tool
files are compared against the SDK provenance fingerprints, never executed.

For packages provide **all three**: `--package-store STORE --package-lock LOCK
--lock-sha256 DIGEST`. The current offline package verifier authenticates lock,
content and native interfaces in temporary local scratch. Without these inputs,
package integrity is NOT_REQUESTED, never a fabricated pass. Native temporary
compiler execution is specific to this explicitly requested package check.

The diagnostic bundle is one bounded JSON report, with no archive, logs, source,
environment values, hostnames or absolute paths. `--output` requires an existing
safe parent and a new filename; symlinks/collisions are rejected and mode is 0600.
It never uploads a report. Installation diagnostics use stable NEBO-INSTALL codes:
0001 path, 0002 concurrency, 0003 collision, 0005 schema, 0006 integrity,
0007 repair identity, 0012 profile/permission, 0013 archive digest requirement,
0014 shell selection, 0015 inventory bound, 0016 local I/O rejection,
0017 interruption. Doctor output rejection is NEBO-DOCTOR-0001.
