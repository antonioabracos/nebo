# SourceFile v0

```txt
Encoding:
UTF-8 without BOM

Content:
byte-preserving; no destructive normalization

Content hash:
FNV-1a 32-bit over the original bytes

Source limit:
request limit must be <= DG-009 source/session default (16 MiB)

Display path:
caller-provided logical relative path using forward slashes

Physical host path:
used only for HostServices open; never retained
```

`SourceFile` does not tokenize, build a LineMap, normalize newlines or depend on
`.no` as a security boundary. The full DiagnosticEngine remains reserved for
MF013; MF011 stores a minimal stable code and byte offset.
