# Source, lexical structure, trivia and comments

Edition 1.0 · current G182 normative bounded profile.

Nebo source is UTF-8; spans refer to original byte offsets. ASCII identifiers
are case-sensitive. Text and Char hold Unicode data, which does not admit Unicode
identifier spellings. Escape decoding, raw text, multiline payloads and
interpolation retain their distinct semantics. LF is canonical layout; CRLF
formatting outside protected trivia/literals does not authorize changing a
payload. Invalid byte sequences and executable bidi/confusable forms fail closed.

The exact 31 keyword spellings and token IDs are frozen in the linked keyword
Registry. The 185 lexical/context rows include active, reserved and rejected
forms; recognition never means public admission. Maximal munch preserves whole
compound tokens. Line comments and depth-bounded nested block comments are
trivia. `doc {}` is a declaration attachment.

Integer radix/separator spellings and signed minimum magnitude are checked by
typed admission; Float lowers to binary64. Char is one Unicode scalar. Quoted
Text decodes valid escapes; r-prefixed Text does not reinterpret them; multiline
Text retains its content. Tagged triple-quoted templates remain outside the
ordinary expression profile. The literal/format tests below freeze admitted
spellings and rejection, without a second lexer implementation.


## N1-source-encoding

Source must be valid UTF-8. Invalid sequences, executable bidi controls and confusable spellings reject; byte offsets are measured in the original bytes. Formatting must preserve literal and comment payloads.

Authority: `docs/reference/language/NEBO-1.0-LEXICAL-SPEC.md`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-identifier-identity

Identifiers use ASCII letters/underscore and subsequent ASCII digits as admitted by the lexical token owner; exact spelling is significant. No Unicode normalization or confusable substitution is implicit; keyword boundaries remain distinct.

Authority: `docs/reference/language/KEYWORD-REGISTRY.tsv`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-maximal-munch

The longest registered token in its admitted context is consumed; compound Unicode tokens retain their whole UTF-8 spans. Recognition alone does not activate a reserved grammar form.

Authority: `docs/reference/language/TOKEN-LEXEME-REGISTRY.tsv`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-comments

Line comments continue to line end. Block comments nest to depth 64 inclusive; depth 65 rejects without an artifact. Comments cannot activate executable statements. A doc block is structured syntax, not trivia.

Authority: `docs/reference/language/NEBO-1.0-LEXICAL-SPEC.md`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-literal-payload

Radix/separator integer spellings preserve their values. Float is binary64, Char is one Unicode scalar, Text retains decoded UTF-8 bytes; raw and multiline forms preserve their respective escape and newline rules.

Authority: `docs/reference/language/NEBO-1.0-LEXICAL-SPEC.md`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

The [rule registry](NORMATIVE-RULE-REGISTRY.tsv) also lists this chapter’s 57 lexical, grammar or declaration obligations. Their linked authority rows retain exact source forms, bounds and negative associations.
