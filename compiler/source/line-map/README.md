# LineMap v0

```txt
Construction:
one linear pass over validated UTF-8 bytes

Stored data:
array of line-start byte offsets

Newlines:
LF = one logical break
CRLF = one logical break
lone CR = one logical break

Line numbers:
1-based

Columns:
1-based Unicode codepoint columns

Offsets:
0-based bytes into the preserved SourceFile content

Lookup:
binary search over line starts
```

An offset inside a UTF-8 continuation byte is invalid. An offset at a newline
maps to the end column of the preceding logical line. The offset immediately
after a newline maps to column 1 of the next line.
