# G04 Text, Char and Bytes foundation example

The executable candidate example is `../g04-text-char-bytes.no`. It exercises
UTF-8 byte length, Unicode scalar counting, Char codepoint extraction and the
static empty Bytes length. Its final value is zero, so successful native
execution exits 0 with empty stdout and stderr.

The candidate does not expose grapheme counting, normalization, codecs,
non-empty Bytes, raw strings, multiline strings or Unicode escape syntax.
