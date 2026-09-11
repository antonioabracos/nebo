# Complete Core v0.1 lexer — MF015

```txt
Identifiers: ASCII only
Integers: checked signed 64-bit magnitude
Text: UTF-8 bytes with \\n \\r \\t \\\\ \\" escapes
Raw/multiline Text: absent
Line comments: // discarded
Block comments: nested trivia, maximum depth 64
Token payloads: pointer-free
Fuzz: bounded deterministic corpus
```

`INT64_MIN` is represented by a `MINUS` token followed by an `INTEGER` token
whose payload is `0x8000000000000000` and whose flags include
`NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE`.

Text token payloads encode a caller-backed literal-pool offset and byte length;
they never expose host pointers.
