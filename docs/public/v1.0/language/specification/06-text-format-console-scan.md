# Text, format, Console and Scan

Edition 1.0 · current G182 normative bounded profile.

Text distinguishes UTF-8 bytes, scalar values and grapheme units. Normalization
is explicit. Borrowed slices obey their owner and unit boundaries. FormatPlan,
interpolation, slash rendering and RenderPlan keep their actual grammar, pure
expression rules, bounded arguments and exact output semantics.

`console()` is canonical; `print` is invalid Nebo, not a compatibility alias.
Retained headless/software nodes and text bytes are observable effects. Typed
ScanPlan mock/stdin/replay preserves parsed values, bounds, EOF/error policy,
cancellation and redaction. All examples use synthetic input. These profiles
make no live desktop, device, external-service or real-secret claim.


## N1-text-units

UTF-8 byte length, Unicode scalar count and grapheme segmentation are distinct operations. Each operation must obey its declared unit and boundary behavior; no implicit normalization is performed.

Authority: `sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-format-and-render

Format/interpolation arguments retain lexical evaluation and typed domain checks. Admitted FormatPlan/RenderPlan profiles preserve exact text and node effects; interpolation expressions must be pure.

Authority: `sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-console-and-scan

console() is the canonical output surface; print is not valid Nebo. Mock/stdin Scan follows its typed result, cancellation, bounds and redaction contracts. Headless/software evidence does not assert live desktop or hardware availability.

Authority: `sdk/contracts/stdlib/STDLIB-PROFILE-BOUNDARIES.tsv`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

The [rule registry](NORMATIVE-RULE-REGISTRY.tsv) also lists this chapter’s 299 lexical, grammar or declaration obligations. Their linked authority rows retain exact source forms, bounds and negative associations.
