# DiagnosticEngine v0

```txt
Diagnostic:
192 bytes, structured and pointer-free in stable IDs

DiagnosticStore:
caller-backed, maximum 512 entries

Catalog:
read-only code/name/message/severity/phase records

Ordering:
SourceId → StartByte → Phase → Code → insertion order

Human format:
path:line:column: severity CODE: message
source line
underline
note
help

No-color:
mandatory and deterministic

ANSI color:
optional renderer flag

JSON:
absent

Nebo Console runtime:
not used

Pointers/timestamps in rendered output:
absent
```

Arguments are byte slices substituted into catalog templates `{0}` and `{1}`.
The store never owns source bytes or message arguments; their owners must remain
valid through finalization/rendering.
