; COLUMN-ROW-TABLE-E-DATASET bounded Column and semantic wrappers historical compatibility path.
;
; ARRAY-VERTICAL-AUD-001 retired the former exact-source dispatch tables.  The active
; token-structural implementation now lives in
; compiler/semantic/structural/legacy_source_verticals.asm and is linked as
; one bounded compiler-semantic object.  This source remains as a migration
; marker so historical documentation paths do not become dangling.
bits 64
section .note.GNU-stack noalloc noexec nowrite progbits
