# Nebo 1.1.0 release notes

Version: `1.1.0`
Language Edition: `1.0`
Publication status: PULL_REQUEST_CANDIDATE
Latest published release: `1.0.1`

The release line adds bounded public functionality while preserving the
stable public source envelope. Integral overload selection is now executable;
collection reads compose through the typed statement owner. The original
public four-Int array example runs unchanged with result 5.

`values.at(index)` remains canonical. Compatibility entry
`NSR-RES-015-COMPAT-1.0.1` admits a bound immutable `Array<Int,4>` and one literal
Int index from 0 to 3. It shares the Array type, lowering and bounds policy;
there is no second indexing engine, hidden mode or default deprecation warning.
General indexing, slicing and user-defined indexing protocols remain reserved.

Long call chains no longer repeatedly infer the same receiver for competing
type families. Large sources avoid redundant scientific fallback candidates.
Collection failures and data/stream examples are verified through actual
source values, missing state, ordering, lazy effects and explicit returns.

The compiler human/machine identity, runtime metadata, SDK packages, manifests,
SBOM and provenance derive from one version authority. The SDK supports an
integrity-checked local upgrade from 1.0.1 with retained-byte rollback.
Compiler ABI, runtime ABI, diagnostic schema and language Edition numbers are
separate from the product version and were not bumped for numerical alignment.

Validation covers the original source, migration, metamorphic equivalence,
composition, bounds, reserved forms, targeted governance/grammar owners and
G203/G204 source-to-runtime programs. Public compatibility inventories retain
257 SymbolIds and 157 diagnostic entries; no runtime export was removed.
The public validation entry point is `scripts/ci-public.sh`.

Only Linux x86-64/System V static ELF is certified. Live display and external
services remain environment-gated. No new external security certification,
signing approval, supported OS or GPU claim is made. The latest published release remains 1.0.1 until separate release publication.
