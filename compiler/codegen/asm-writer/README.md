# AssemblyWriter v0

A deterministic, caller-buffered NASM text writer. Appends are checked before
copying, finalization seals the bytes with FNV-1a, and sealed validation rejects
tampering. Source Text is never accepted as trusted Assembly by this layer.

Finalization also freezes the canonical LF line count. Sealed validation
recomputes both FNV-1a and the line count so byte or metadata tampering is
rejected before the backend result is consumed.
