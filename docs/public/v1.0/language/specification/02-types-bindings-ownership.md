# Types, bindings, constants and ownership

Edition 1.0 · current G182 normative bounded profile.

Types have identity beyond spelling. Bool, Int64, binary64 Float, Unicode Char,
UTF-8 Text and Bytes do not implicitly coerce at a binding boundary. Inference
and explicit one-shot initialization preserve that identity. `.name` binds a
value; `.mutable` permits same-type assignment; uppercase constants cannot be
reassigned. A separate `Type.name;` declaration requires definite initialization.

Aliases retain the referent layout within their admitted nominal profile.
Newtypes require explicit wrapping/unwrapping; enums preserve active payloads.
Generic constraints and const arguments remain checked in their bounded scalar
profile. Struct field evaluation follows source order, not storage order.

Move invalidates the old binding. Copy and explicit clone do not merge owned
stores. Borrowed views cannot outlive their owner, escape, or permit prohibited
mutation/drop/reset. Cleanup applies on every reachable exit and failure path.
Dict/Set, sequential and relational collections retain the exact key/value,
hash/equality, mutation, capacity and ownership rules of their public entries.
`Map` is not introduced as a second spelling for `Dict`.


## N1-builtin-types

Bool, Int64, binary64 Float, Unicode Char, UTF-8 Text and Bytes retain distinct typed identities.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S02-F001`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-inference-and-binding

Direct inference and explicit one-shot initialization agree; assignment preserves type and mutability.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S02-F002`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-no-coercions

No implicit Bool/Int/Float/Char/Text conversion at binding boundaries; rejected initializer retains causal type error.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S02-F003`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-nominal-identity

Alias layout equals referent layout; newtype requires explicit construction/unwrap; enum discriminants and active payloads remain distinct.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S02-F004`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-generic-constraints

Supported scalar generic constraints are checked, not erased; const arguments specialize independently.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S02-F005`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-explicit-conversions

Narrowing, textual parsing and numeric rounding use explicit operations with checked domain/error behavior.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S02-F007`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-move

Move transfers ownership exactly once and invalidates the old binding.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S03-F001`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-copy-clone

Value copies and explicit owned clones remain independent; clone allocation is accounted and released.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S03-F002`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-borrow-aliasing

Shared/unique views constrain mutation, reset, drop and move until release.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S03-F003`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-lifetime-escape

Borrow cannot escape its owner; function result ownership is explicit and caller-owned.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S03-F004`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-cleanup

Success, early return and allocation failure release all live resources exactly once.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S03-F005`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-layout-ownership

Distinct live owned values must remain independent and valid through their permitted lifetimes. Internal descriptor offsets and generation representation are not language syntax.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S03-F006`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

The [rule registry](NORMATIVE-RULE-REGISTRY.tsv) also lists this chapter’s 313 lexical, grammar or declaration obligations. Their linked authority rows retain exact source forms, bounds and negative associations.
