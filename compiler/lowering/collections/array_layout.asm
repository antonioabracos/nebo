; COLECOES-PRIMITIVAS-PF004 internal Array<Int,4> DataLayout
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/collections/array_layout.inc"
section .text
NEBOC_ABI_FUNCTION neboc_colecoes_primitivas_array_layout
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_ARRAY_LAYOUT_SIZE_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_LAYOUT_ALIGNMENT_OFFSET],0
 mov qword [rdi+neboc_colecoes_primitivas_ARRAY_LAYOUT_STRIDE_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_LAYOUT_ALLOCATION_COUNT_OFFSET],0
 mov qword [rdi+neboc_colecoes_primitivas_ARRAY_LAYOUT_DIAGNOSTIC_OFFSET],0
 cmp qword [rdi+neboc_colecoes_primitivas_ARRAY_LAYOUT_ELEMENT_SIZE_OFFSET],8
 jne .invariant
 cmp qword [rdi+NEBOC_ARRAY_LAYOUT_ELEMENT_COUNT_OFFSET],4
 jne .invariant
 mov qword [rdi+NEBOC_ARRAY_LAYOUT_SIZE_OFFSET],32
 mov qword [rdi+NEBOC_ARRAY_LAYOUT_ALIGNMENT_OFFSET],8
 mov qword [rdi+neboc_colecoes_primitivas_ARRAY_LAYOUT_STRIDE_OFFSET],8
 xor eax,eax
 ret
.invariant:
 mov qword [rdi+neboc_colecoes_primitivas_ARRAY_LAYOUT_DIAGNOSTIC_OFFSET],NEBOC_ARRAY_LAYOUT_DIAG_INVARIANT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
