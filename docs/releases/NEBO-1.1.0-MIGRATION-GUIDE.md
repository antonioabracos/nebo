# Nebo 1.1.0 migration guide

Version: `1.1.0`
Language Edition: `1.0`

NO_SOURCE_MIGRATION_REQUIRED for the stable public 1.0.1 source envelope.
The original four-Int array example compiles normally and returns 5. Optional
migration replaces `values[index]` with `values.at(index)` after checking the
receiver type. An untyped four-Int literal can remain unchanged. Do not apply
this rewrite to arbitrary receiver or index expressions.

No compatibility flag or warning suppression is required. The bracket alias
has no scheduled removal in Edition 1.0. General indexing, slicing and custom
index protocols are still reserved. Bounds follow the canonical checked API.

The five source-visible historical examples using Vector implementation
syntax, Task descriptors, standalone top-level visual summary, or deferDrop
cleanup are not covered by a stable source promise. They remain listed in
VERSION-DELTA.tsv and PUBLIC-MATURITY-REVIEW.json with their original maturity
evidence. The typed summary API remains available inside start(); this is not
a promise to accept general top-level statements. The mixed callable atlas
contains unstable/post-1.0 forms and incomplete optional-module imports. It
now terminates with the corresponding diagnostic; it is not an admitted source
program. Current scientific programs use explicit imports and typed reduction
arguments.

Use fresh, caller-owned directories for local SDK operations. With restored
SDK directories in `sdk-old` and `sdk-new`, run from the source checkout:

```bash
python3 -B scripts/rf204/nebo-sdk-lifecycle.py install sdk-old build/local-nebo --profile prefix
python3 -B scripts/rf204/nebo-sdk-lifecycle.py verify build/local-nebo
python3 -B scripts/rf204/nebo-sdk-lifecycle.py upgrade sdk-new build/local-nebo
python3 -B scripts/rf204/nebo-sdk-lifecycle.py rollback build/local-nebo
python3 -B scripts/rf204/nebo-sdk-lifecycle.py uninstall build/local-nebo
```

The parent directory must already exist and belong to the caller. Upgrade
requires the same Edition/target and unchanged public compatibility inventories;
existing serialized interfaces cannot disappear or change. Rollback restores
the retained original SDK, rather than rewriting old source or interfaces.
Unknown caller files are not silently discarded. No global installation or
shell-profile edit is performed.
