; VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-PF004 allocation-free copy/read/len and checked scientific helpers
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/collections/vector_int4_runtime.inc"
section .text
NEBOC_ABI_FUNCTION neboc_vector_int4_copy
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

NEBOC_ABI_FUNCTION neboc_vector_int4_read
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBOC_VECTOR_INT4_LENGTH
 jae .bounds
 mov rax,[rdi+rsi*8]
 mov [rdx],rax
 xor eax,eax
 ret
.bounds: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_vector_int4_len
 mov eax,NEBOC_VECTOR_INT4_LENGTH
 ret

NEBOC_ABI_FUNCTION neboc_vector_int4_sum
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 xor r8,r8
 xor ecx,ecx
.loop:
 add r8,[rdi+rcx*8]
 jo .overflow
 inc ecx
 cmp ecx,NEBOC_VECTOR_INT4_LENGTH
 jb .loop
 mov [rsi],r8
 xor eax,eax
 ret
.overflow: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_vector_int4_dot
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 xor r8,r8
 xor ecx,ecx
.loop:
 mov rax,[rdi+rcx*8]
 imul rax,qword [rsi+rcx*8]
 jo .overflow
 add r8,rax
 jo .overflow
 inc ecx
 cmp ecx,NEBOC_VECTOR_INT4_LENGTH
 jb .loop
 mov [rdx],r8
 xor eax,eax
 ret
.overflow: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
