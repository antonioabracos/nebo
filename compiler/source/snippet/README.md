# Snippet extraction v0

A snippet borrows one logical source line. It stores a stable logical relative
path, a bounded UTF-8 byte window and highlight offsets relative to that window.

```txt
Default maximum:
160 bytes

Hard maximum:
512 bytes

Truncation:
deterministic around the primary span start

UTF-8:
window boundaries never split a continuation sequence

Paths:
absolute paths, backslashes, NUL and drive-colon forms are rejected

Multi-line spans:
MF012 returns the first-line snippet only when the span is single-line;
MF013 can render multiple lines by requesting one snippet per line
```
