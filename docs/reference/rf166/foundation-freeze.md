# RF166 foundation freeze

G149 establishes one factual authority for the post-RF148 repository and one
normative plan for G150-G166. It deliberately exposes no new source syntax,
public compiler command, interface file, prelude binding, or block comment.
The callable atlas classifies G149 as `INTERNAL_BOUNDED`; the internal Assembly
ABI makes the freeze executable without promoting roadmap claims to product.

The live authority has 12 facts: five `MATERIAL`, five `ASSUMED`, one
`RESERVED`, and one `REJECTED`. The 14 decisions cover eight import and
qualification forms, two documentation forms, one interface form, and three
prelude/standard-library rules. `00-DECISION-REGISTER.tsv` is the canonical
decision table; the syntax, schema, diagnostic, crosswalk, interface, and
prelude files are projections of it.

The global plan contains 146 catalog-authenticated front IDs connected by 145
conservative linear edges. Its four program packs contain 48, 40, 40, and 18
fronts. G164 remains a P03 owner even though the optimized order places it
immediately after G155. `FRONT-DAG.tsv` is derived from the corrected catalog
and is verified against that catalog on every G149 validation.

## Frozen boundaries

- Existing public `module-check`/`link` behavior remains material.
- Canonical simple imports, capsules, selective imports, reexports, and
  namespace qualification remain assumed until G151-G152 integrate them.
- Wildcard imports are rejected; `::` remains reserved.
- Singular `doc {}` is the candidate; plural `docs {}` is rejected and G155
  owns the eventual targeted diagnostic and quick-fix.
- `.ni` is the only candidate interface extension; G154 owns public round-trip
  and compatibility proof.
- The SDK distributes the Standard Library, but only a small edition-owned
  prelude may become implicit; G163 owns that integration and `--no-prelude`.
- `/* ... */` remains reserved until G164.
- The proposed `language-contract` and `roadmap-audit` CLI routes are not public
  in G149.

The internal ABI, ownership, layouts, and failure behavior are specified in
`sdk/interfaces/modules/RF166-FOUNDATION.md`. All reports are caller-owned,
bounded, synchronous, deterministic, and failure atomic.
