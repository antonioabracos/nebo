; COLUMN-ROW-TABLE-E-DATASET-PF004 allocation-free internal Column<Int>#4 helpers
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/collections/column_int4_runtime.inc"
section .text
NEBOC_ABI_FUNCTION neboc_column_copy
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rsi]
 mov [rdi],rax
 mov rax,[rsi+8]
 mov [rdi+8],rax
 mov rax,[rsi+16]
 mov [rdi+16],rax
 mov rax,[rsi+24]
 mov [rdi+24],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_COLUMN_RUNTIME_INVALID
 ret
NEBOC_ABI_FUNCTION neboc_column_read
 test rdi,rdi
 jz .read_invalid
 test rdx,rdx
 jz .read_invalid
 cmp rsi,3
 ja .bounds
 mov rax,[rdi+rsi*8]
 mov [rdx],rax
 xor eax,eax
 ret
.bounds: mov eax,NEBOC_COLUMN_RUNTIME_BOUNDS
 ret
.read_invalid: mov eax,NEBOC_COLUMN_RUNTIME_INVALID
 ret
NEBOC_ABI_FUNCTION neboc_column_len
 mov eax,4
 ret
NEBOC_ABI_FUNCTION neboc_column_row_table_e_dataset_column_count_missing
 xor eax,eax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
