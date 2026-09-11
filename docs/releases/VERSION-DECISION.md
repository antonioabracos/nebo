# Nebo 1.1.0 version decision

Product version: **1.1.0**. Language Edition: **1.0**.
Decision: **BACKWARD_COMPATIBLE_PUBLIC_ADDITIONS**.
Publication status: **FINAL_RELEASE_READY**.
Latest published release: **1.0.1**.

Bounded overload selection, composable Array reads and machine-readable CLI
identity are public additions. The published immutable four-Int array indexing
contract remains available without a flag or a default warning. Both the
original example and its optional `.at()` migration return 5. General indexing,
slicing and user-defined indexing protocols remain reserved.

The permanent [indexing tests](../../tests/release/indexing-compatibility/validate.sh)
cover 98 cases, including 32 equivalent native-output pairs. The
[compatibility matrix](COMPATIBILITY-1.0.1-TO-1.1.0.tsv) records the stable
contract and the five disclosed experimental source differences. See the
[migration guide](NEBO-1.1.0-MIGRATION-GUIDE.md) for their boundaries.

Two complexity fixes resolve 166 formerly timed-out cases: 78 accepted programs
and 88 expected rejections. The measured per-case budget is three seconds,
except for the large mixed atlas with an eight-second budget. The collection
and data/stream validators retain independent values, negative controls,
ordering, missing-state and lazy-effect checks.

Only Linux x86-64/System V static ELF is supported. Edition, ABI identifiers
and schema versions are separate from the product version. This source
makes no additional operating-system, GPU, external-service or certification
claim. Source integration and post-merge CI are complete. The release date is unset;
tag, GitHub Release and assets await a separate RELEASE_GO.
