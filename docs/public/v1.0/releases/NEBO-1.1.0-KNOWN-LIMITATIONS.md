# Nebo 1.1.0 known limitations

Version: `1.1.0`
Language Edition: `1.0`

The supported native target is Linux x86-64/System V static ELF. NASM, GNU ld,
Ninja and Python are local prerequisites. There is no independent bootstrap,
second certified operating system, GPU certification or external security audit.

Legacy indexing is limited to a bound immutable four-Int Array and one literal
Int index. Dynamic indices, other receiver types, mutable bracket access and
slicing are not activated. The existing canonical compile-time bounds
rejection uses diagnostic code NEBO_TUPLE_INDEX_OUT_OF_RANGE.

Source-visible experimental and contract-only fixtures are not stable source
APIs. Five old implementation examples still reject. The mixed callable atlas
also rejects: its public entry lacks a required scientific-module import and
its native analysis finds an invalid tensor reduction signature. These are
bounded diagnostic observations, not successful source admission.

The 166 former admission timeouts are resolved individually. Long receiver
chains and redundant scientific fallback work were repaired. Current collection
and data/stream validators pass with typed value, ownership, cleanup and
failure oracles. Historical descriptor fixtures and old whole-source probe
wrappers remain historical evidence rather than current source conformance.

Console trace channels are test interfaces. Visible X11 presentation requires
the relevant environment, and no live desktop, service or remote publication
is certified by local headless tests. External approval gates remain pending.

Historical roadmap orchestration and the old release materializer are excluded
from this source profile. The compatibility aliases `roadmap-closeout rf166`,
`selftest modules-docs-devex` and `release materialize` reject with an explicit
diagnostic. Use `bash scripts/ci-public.sh` for current validation. These
operational exclusions do not change source parsing or runtime semantics.
