; COLUMN-ROW-TABLE-E-DATASET-PF004 fixed inline Column layout property query
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/collections/column_layout.inc"
section .rodata align=8
properties: dq 32,8,8,0,8,16,24,0,0
property_count equ ($-properties)/8
section .text
NEBOC_ABI_FUNCTION neboc_column_layout_property
 cmp rdi,property_count
 jae .invalid
 lea rax,[rel properties]
 mov rax,[rax+rdi*8]
 ret
.invalid: mov rax,-1
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
