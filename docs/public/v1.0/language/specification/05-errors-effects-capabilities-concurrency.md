# Errors, effects, capabilities and concurrency

Edition 1.0 · current G182 normative bounded profile.

Option/Result preserve the active payload and its type; error identity and
context remain structured. `unwrapOr(value)` evaluates the fallback value eagerly.
The admitted lazy/coalescing profiles do not promise arbitrary effectful callbacks.
Propagation returns an active error without executing the later success path.

Invalid source rejects before artifact publication. Accepted source may fail at
runtime with a typed Result/Error or defined trap; these failures must not be
misreported as compile diagnostics. Output and resource atomicity are tested at
the actual sink. Imports cannot grant or fabricate capabilities. Host authority,
attenuation, privacy and provenance retain their distinct contracts; their native
metadata layouts are not extra public constructors.

The measured task profile admits noncapturing callbacks and single-consumer
Futures. Bounded channels are FIFO; cancellation and deterministic cooperative
admission preserve observable order. Owned handles, guards and resources cannot
escape or double-consume. This baseline does not specify preemptive async or a
general cross-thread language memory model. Native synchronization tests do not
promote an unexposed source operation to stable public availability.


## N1-effect-lattice

Effect tracking is a compiler contract, not a public constructor or a promise that its internal bit layout is a language type. Public effectful calls remain subject to declared purity and authority.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S04-F001`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-source-effect-inference

Interpolation permits only pure expressions, including transitive callees; discarded effects still execute outside pure contexts.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S04-F002`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-capability-grants

Imports grant no authority. Only host-authenticated, scoped capabilities authorize their corresponding sinks; attenuation cannot amplify the grant. The native grant representation is not public syntax.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S04-F003`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-policy-before-sink

An operation denied by the admitted capability policy must fail before its sink; a failed authorization must not consume the capability budget. Internal policy request layouts are not public constructors.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S04-F005`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-privacy-and-trust

Sensitive input must follow the admitted redaction and flow policy; it must not appear in a redacted sink. Native Sensitive/Trusted metadata does not declare additional public source constructors.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S04-F006`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-provenance

Provenance metadata must preserve authenticated source/transform relationships when that tooling contract is used. Metadata lineage does not add a source-language provenance constructor.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S04-F007`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-option-layout

Option has distinct Some(payload) and None() variants. Some carries the declared payload type; None carries no payload. Only the selected variant is observed; invalid payloads and wrong observers reject.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S05-F001`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-result-layout

Ok/Err preserve distinct success/error types and owned payloads across function returns.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S05-F002`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-fallback-laziness

unwrapOr(value) evaluates its value argument eagerly. The admitted ?? and combinator profiles select the active variant; this does not admit arbitrary effectful callback forms.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S05-F003`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-error-identity

Error code/category/span/context and cause remain structured; messages are derived from active error identity and caller context.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S05-F004`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-match

Current enum matching observes only the selected active variant and rejects invalid patterns according to the finite source profile.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S05-F005`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-propagation

? retains the enclosing supported Result type and propagates the active error without reusing helper status as payload.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S05-F006`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-tasks-futures

Within the separately measured material profile, without stable-availability promotion: Supported noncapturing task callbacks execute once; Future is single-consumer and map preserves effects.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S06-F004`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-channels

Within the separately measured material profile, without stable-availability promotion: Bounded FIFO transport preserves values, capacity errors and close behavior; source loops compose with independent random states.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S06-F005`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-cancellation-scheduling

Within the separately measured material profile, without stable-availability promotion: Cancellation blocks admission; deterministic scheduler/select order is bounded, not a promise of preemptive async source.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S06-F006`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-resource-closure

Private filesystem operations enforce beneath/no-symlink paths and close resources. Native synchronization semantics are a separate internal supplement and do not grant additional stable source APIs.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S06-F007`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

The [rule registry](NORMATIVE-RULE-REGISTRY.tsv) also lists this chapter’s 16 lexical, grammar or declaration obligations. Their linked authority rows retain exact source forms, bounds and negative associations.
