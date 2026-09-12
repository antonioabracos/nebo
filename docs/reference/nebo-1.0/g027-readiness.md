# G027 local portability and readiness boundary

G027 is the single local inspection point for Nebo's target, ABI/runtime,
edition, conformance, security, release-dry-run, documentation, and readiness
facts. Run `neboc nebo-1.0-readiness` for the aggregate canonical JSON report,
or use the narrower commands listed by `neboc --help`.

The target identifiers intentionally expose both naming layers:

- `x86_64-systemv-elf-linux` is the compatibility-contract identifier;
- `x86_64-unknown-linux-systemv` is the normalized target triple.

Only that normalized x86-64 triple is currently supported by both a backend
and runtime. AArch64 and Wasm descriptors are useful for portability analysis,
but are not production-target evidence.

ABI version `0.0`, runtime version `0.0`, and object-metadata version `1` are
internal compatibility generations. They do not have to match the user-facing
compiler version `1.1.0`. Link compatibility validates the complete bounded
object set before publishing a result.

The legacy aggregate status is an implementation inspection result and does not
describe publication. The public source is FINAL_RELEASE.
Latest published release: 1.1.0. Release date: 2026-09-12.
Release timestamp (UTC): 2026-09-12T07:14:22Z. Tag: nebo-v1.1.0.
Publication through GitHub Release is authorized by RELEASE_GO.
Historical release materialization and roadmap
orchestration are excluded. Run `bash scripts/ci-public.sh` for the current
bounded validation suite. No inspection result grants release authorization.
