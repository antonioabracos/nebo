# Bounded ABI conformance model

This document describes only the bounded
native ABI and compiler/tooling model. Its numeric edition fields identify
model generations; the current public language Edition is 1.0. It does not turn
internal ABI-only features into public source syntax.

## Target and version rules

- `RULE-101`: effects form the frozen fourteen-atom finite lattice.
- `RULE-102`: unknown or hidden effects are rejected before publication.
- `RULE-201`: effectful execution requires exact scoped capability and budget.
- `RULE-202`: wrong authority, scope, revocation or exhaustion is typed denial.
- `RULE-301`: model generation 1 is legacy; model generation 2 is current.
- `RULE-302`: unknown editions and unsafe automatic migration are rejected.
- `RULE-401`: the tested native target is x86_64 System V ELF Linux, static/no-libc.
- `RULE-402`: an unavailable target cannot be reported as tested.
- `RULE-501`: plugin manifests bind target, ABI/runtime, exports and content hash.
- `RULE-502`: unverified plugins, ambient authority and code shipping are denied.
- `RULE-601`: provenance and audit records are versioned append-only hash chains.
- `RULE-602`: mutation, missing lineage, secret sinks and chain corruption fail.

## Diagnostics and runtime

Every normative negative has a stable typed status. Operations with caller-owned
outputs validate before publication and preserve state on failure. Native calls
use the x86-64 System V ABI, preserve stack alignment and produce static ELF
without C or libc dependencies. Bounds in the corresponding RF27 contracts are
part of conformance.

## Conformance manifest

`conformance/rf27/manifest.tsv` binds each case to a numeric rule, class,
supported target, ABI, edition, expected status and fixture identity. The
conformance tool rejects unknown targets, drift, missing rules, bad editions or
result mismatches generically; it never dispatches by fixture filename.
# Canonical control headers (Nebo 1.0)

The sole public control grammar is:

```txt
if (BoolExpression) Block [else Block | else if ...]
while (BoolExpression) Block
for (Identifier in Identifier) Block
loop Block
```

`loop` is conditionless. `when`, `switch`, and `do-while` are not Nebo 1.0
productions. Parentheses are syntactic delimiters only and do not change AST,
evaluation order, scope, lowering, runtime, or ABI.
