; Nebo Assembly — TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF004 allocation-free PositiveInt runtime helpers
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/domain/positive_int_runtime.inc"

section .text
; rdi signed Int -> rax result tag, rdx payload
NEBOC_ABI_FUNCTION nebo_positive_int_try
 test rdi,rdi
 jle .err
 xor eax,eax
 mov rdx,rdi
 ret
.err:
 mov eax,NEBO_POSITIVE_INT_RESULT_ERR
 mov edx,NEBO_POSITIVE_INT_ERROR_NON_POSITIVE
 ret

; rdi result tag -> rax Bool
NEBOC_ABI_FUNCTION nebo_positive_int_is_ok
 test rdi,rdi
 sete al
 movzx eax,al
 ret

NEBOC_ABI_FUNCTION nebo_positive_int_is_err
 test rdi,rdi
 setne al
 movzx eax,al
 ret

; rdi tag, rsi payload, rdx positive fallback -> rax PositiveInt
NEBOC_ABI_FUNCTION nebo_positive_int_unwrap_or
 test rdi,rdi
 cmovz rdx,rsi
 mov rax,rdx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
