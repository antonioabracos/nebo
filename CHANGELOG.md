# Changelog

All notable changes to Nebo are recorded in this file.

## [1.1.0] - 2026-09-12

### Added

- Bounded overload selection and the current typed collection composition.
- Machine-readable `neboc --version-json`, tied to the canonical product identity.
- A permanent version consistency checker, with adversarial self-tests.

### Fixed

- Preserve public 1.0.1 four-Int array indexing source without migration.
- Lower legacy reads through the same Array owner as `.at()`, preserving
  adjacent statements, two arrays, Console calls and explicit returns.
- Forward the existing build `--quiet` option through the normal CLI host.
- Bound repeated receiver inference in long method chains and avoid redundant
  scientific fallback candidates in large source files.
- Validate collection failure behavior and data/stream examples with typed
  source values, lazy effects and current SDK layout.

### Compatibility

- Language Edition remains 1.0. General indexing and slicing remain reserved.
- Deprecation of the bounded bracket alias is documentary; no default warning.
- SDK product identity, package metadata and local upgrade/rollback follow the
  canonical release version. Public 1.0.1 identities remain historical inputs.
- Source-visible experimental examples are outside the stable source promise;
  their observed differences are listed in the migration guide.

### Publication

- Publication status: FINAL_RELEASE; publication authorized by RELEASE_GO.
- Release date: 2026-09-12; release timestamp (UTC): 2026-09-12T07:14:22Z.
- Latest published release: 1.1.0; tag: `nebo-v1.1.0`.

## [1.0.1] - Published

Corrective public snapshot: repaired Buffer route selection and Console scan
composition, corrected seven System V stack-alignment sites, and added the
associated regression fixtures. Edition 1.0 and the supported target were
preserved. See the [original release](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.1).

## [1.0.0] - Published

First stable public release for Linux x86-64/System V static ELF, with the
bounded language/runtime contract, offline source distribution and integrity
metadata. See the [original release](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.0).
