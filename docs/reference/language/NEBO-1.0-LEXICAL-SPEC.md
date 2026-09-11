# G174 current lexical freeze

This is the current source-level freeze of the G173 authenticated Linux x86-64
bounded baseline, not a declaration that all future language features exist.
The corrected G174 contract takes precedence over old RF204 snapshot documents.
source syntax authority. In particular its old parser paths and assertion that
`neboc format` is unavailable are superseded here.

UTF-8 is validated without silent normalization or confusable substitution.
Identifiers use the exact native ASCII identifier/keyword classification.
Text and Char retain Unicode data; source spans count UTF-8 bytes. Malformed
UTF-8, bidi controls and confusable operators in executable contexts fail closed.
Native comment security applies independently; comments never activate syntax.
LF is the canonical layout. Formatting CRLF outside protected literals/trivia
may produce LF; literal/comment bytes are preserved, including interior spaces.

`TOKEN-LEXEME-REGISTRY.tsv` retains all 185 canonical operator identities,
codepoints, UTF-8 bytes, context, fixity, precedence, exact aliases and evidence.
Metavariable forms such as `<...>` describe syntax, not one literal token.
There are 136 active operator forms plus active nested block-comment trivia,
22 still-reserved forms and 26 rejected forms. The old declaration's
`current_state` strings predate the material RF172 implementation and are not
used as execution proof. Operator class/identity/provenance are unchanged.
`KEYWORD-REGISTRY.tsv` freezes all 31 exact keyword spellings and token IDs.
Keyword recognition is separate from parser-context admission.

The lexer uses maximal munch. Compound `⁻¹`, `∇·`, `∇×`, `°C`, `°F`, range and
optional-flow spellings retain their complete byte spans. Nine exact Unicode
aliases share their ASCII operation token with explicit spelling provenance.
Lookalikes are never aliases. Caret is power, never XOR. `::`, wildcard imports,
ASCII three-dot ranges and user-defined operator spellings remain closed.

Native integer tokens preserve radix/separator and minimum-magnitude flags;
semantic owners validate type and overflow. Float decimal tokens reach exact
binary64 lowering. Raw and multiline Text, Char and interpolated Text keep
literal-pool/source provenance. No whitespace-erasing projection may compare
literal contents. Interpolation chunks and embedded expression tokens are
owned by the native lexer and typed interpolation plan.

Tagged triple-quoted Text has lexer provenance and a native template-plan
owner, but is not admitted as an ordinary public expression by this baseline.
`NON-EXECUTABLE-FORMS.tsv` records this boundary and explicit rejection probes;
the grammar does not advertise it as a working public production. Reserved
control words similarly do not acquire executable semantics from tokenization.

Line comments run through line end. Nested block comments allow depth 64;
depth 65 is rejected. The shared native scanner owns delimiters, nesting and
security. No second lexer or parser is used to accept programs in G174.

After this freeze, changing any spelling, classification, grammar or profile
requires an explicit Edition/compatibility/migration decision and new source,
negative, deterministic and formatter differential evidence. No automatic
reserved activation or source migration is authorized by this freeze.
