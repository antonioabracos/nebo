; ARITMETICA-CHECKED-E-ASSIGNMENT-COMPOSTO signed Int division/remainder, truncating toward zero.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

section .text
; checked_divide(dividend, divisor, out_quotient*)
NEBOC_ABI_FUNCTION neboc_core_checked_divide
 test rdx,rdx
 jz .div_invalid
 mov r8,rdx
 test rsi,rsi
 jz .div_zero
 mov rax,0x8000000000000000
 cmp rdi,rax
 jne .div_execute
 cmp rsi,-1
 je .div_overflow
.div_execute:
 mov rax,rdi
 mov rcx,rsi
 cqo
 idiv rcx
 mov [r8],rax
 xor eax,eax
 ret
.div_overflow:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.div_zero:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.div_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; checked_remainder(dividend, divisor, out_remainder*)
NEBOC_ABI_FUNCTION neboc_core_checked_remainder
 test rdx,rdx
 jz .rem_invalid
 mov r8,rdx
 test rsi,rsi
 jz .rem_zero
 mov rax,0x8000000000000000
 cmp rdi,rax
 jne .rem_execute
 cmp rsi,-1
 je .rem_minimum
.rem_execute:
 mov rax,rdi
 mov rcx,rsi
 cqo
 idiv rcx
 mov [r8],rdx
 xor eax,eax
 ret
.rem_minimum:
 mov qword [r8],0
 xor eax,eax
 ret
.rem_zero:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.rem_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
