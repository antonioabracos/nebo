; structs_enums_variants_e_tipos_do_programador programmer-defined types historical compatibility path.
;
; ARRAY-VERTICAL-AUD-001 retired the former exact-source dispatch tables.  The active
; token-structural implementation now lives in
; compiler/semantic/structural/programmer_types_structural.asm and is linked as
; one bounded compiler-semantic object.  This source remains as a migration
; marker so historical documentation paths do not become dangling.
bits 64
section .note.GNU-stack noalloc noexec nowrite progbits
