; ARITMETICA-CHECKED-E-ASSIGNMENT-COMPOSTO checked signed Int arithmetic with atomic output.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

section .text
; All functions use (left, right, out*) and write only after success.
NEBOC_ABI_FUNCTION neboc_core_checked_add
 test rdx,rdx
 jz .add_invalid
 mov rax,rdi
 add rax,rsi
 jo .add_overflow
 mov [rdx],rax
 xor eax,eax
 ret
.add_overflow:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.add_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_core_checked_subtract
 test rdx,rdx
 jz .sub_invalid
 mov rax,rdi
 sub rax,rsi
 jo .sub_overflow
 mov [rdx],rax
 xor eax,eax
 ret
.sub_overflow:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.sub_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_core_checked_multiply
 test rdx,rdx
 jz .mul_invalid
 mov rax,rdi
 imul rax,rsi
 jo .mul_overflow
 mov [rdx],rax
 xor eax,eax
 ret
.mul_overflow:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.mul_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
