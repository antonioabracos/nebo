# Expressions, operators and control flow

Edition 1.0 · current G182 normative bounded profile.

Ordinary operands evaluate left to right once. The exact lexical-context
Registry selects fixity before precedence; stronger numeric binding power binds
first. Power is right associative: `2^3^2` is 512, `-2^2` is -4 and `(-2)^2`
is 4. Nonassociative and domain restrictions remain mandatory. `×` is not a
scalar `*` alias. English `and`, `or`, and `not` are rejected; use `&&`, `||`,
`!` or their exact ∧/∨/¬ aliases. A skipped Boolean operand has no effects.

Branches, loops, break/continue, match, return and discard preserve lexical scope
and ownership. The admitted `for` header names a previously bound iterable,
optionally an index and a finite comparison filter. It does not accept an
arbitrary inline range expression. Match distinguishes active payloads and
requires the admitted finite coverage; `None()` has no payload binding.

Receiver calls and typed constructors are resolved before source execution.
Optional flow and explicit propagation preserve variant identity. Scientific
operator profiles are bounded finite grammars; their presence in this union
of forms does not grant unrestricted symbolic mathematics or adjacent effects.


## N1-binary-order

Evaluate ordinary operands left to right exactly once, including owned Bytes operands.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S01-F001`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-aggregate-order

List arguments and named product fields evaluate in lexical source order, independent of storage field order.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S01-F003`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-short-circuit

&& and its exact alias ∧, and || and its exact alias ∨, evaluate the right operand only when required. The English words and/or/not are not executable aliases in Edition 1.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S01-F004`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-temporary-lifetime

Temporaries remain valid through use, and independent returned owned values do not alias.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S01-F005`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-discard-and-return

Discard keeps effects; return suppresses subsequent control paths and runs required cleanup.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S01-F006`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-precedence-associativity

The registered binding powers and associativity govern grouping: power is right associative and binds more strongly than unary minus; parentheses explicitly override grouping.

Authority: `docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0/00-PRECEDENCE-REGISTRY.tsv`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

The [rule registry](NORMATIVE-RULE-REGISTRY.tsv) also lists this chapter’s 349 lexical, grammar or declaration obligations. Their linked authority rows retain exact source forms, bounds and negative associations.

## Edition 1.0 public indexing compatibility

`NSR-RES-015-COMPAT-1.0.1` preserves public 1.0.1 reads from a bound immutable
`Array<Int,4>` with a single literal index from 0 to 3. General indexing and
slicing remain RESERVED. Prefer `values.at(index)` in new source; existing
`values[index]` needs no migration, warning suppression or compatibility flag.
Both spellings use the same Array owner and checked bounds policy.
No user-defined index protocol or automatic quick fix is enabled.
