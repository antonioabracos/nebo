# MF012 source-location tests

The native test binary is parameterized by the normative numeric suffix:

```txt
4 → LF LineMap
5 → CRLF logical equivalence
6 → byte offset to 1-based Unicode codepoint column; checked spans/snippet
8 → deterministic semantic output and logical relative path
```
