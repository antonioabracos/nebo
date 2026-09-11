# Edition 1.0 source freeze and compatibility

Edition is not a version bump. The existing compiler accepts explicit Edition
IDs 1 and 2 for its bounded current syntax; the native Registry and compatibility
owners reject unknown IDs. The current ABI/runtime fields remain unchanged.
Every active or protected operator and public grammar production has an
Edition row in `EDITION-1.0-FEATURE-MATRIX.tsv`. A reserved spelling stays closed
under both admitted selections. Unknown future IDs fail before source mutation.

`neboc migrate --from 1 --to 2 --features ...` is a deterministic mechanical
preview. It normalizes a bounded feature set, changes no files, rejects unsafe
or unknown directions and is idempotent for duplicate/reordered features.
The native lifecycle tests independently exercise feature masks, version and
target compatibility, reviewed class transitions, deprecation, migration
manifest validation, reversible byte transforms and failure atomicity.
No preview grants permission to activate a Registry entry.

A future language change must explicitly identify affected forms, compatible
Editions, diagnostics, migration (or justified absence), negative associations
and formatter semantic equivalence. Until that decision, this G174 freeze
preserves exact syntax and classifications. G175 is only the recommended next
optimized-order group; it is not started here.
