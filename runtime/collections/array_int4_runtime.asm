; COLECOES-PRIMITIVAS-PF004 allocation-free copy and checked read helpers
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/collections/array_int4_runtime.inc"
section .text
NEBOC_ABI_FUNCTION neboc_array_int4_copy
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
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_array_int4_read
 test rdi,rdi
 jz .invalid_read
 test rdx,rdx
 jz .invalid_read
 cmp rsi,NEBOC_ARRAY_INT4_LENGTH
 jae .bounds
 mov rax,[rdi+rsi*8]
 mov [rdx],rax
 xor eax,eax
 ret
.bounds: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid_read: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_array_int4_len
 mov eax,NEBOC_ARRAY_INT4_LENGTH
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
