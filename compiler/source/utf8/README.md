# UTF-8 validation v0

The validator is strict and deterministic. It rejects:

- truncated sequences;
- continuation bytes without a lead byte;
- overlong encodings;
- UTF-16 surrogate code points;
- code points above `U+10FFFF`.

The validator reports the byte offset of the first invalid lead or continuation.
BOM policy is owned by `SourceFile`: Core v0.1 requires UTF-8 **without BOM**.
