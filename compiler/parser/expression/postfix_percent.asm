bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_PERCENT_NOT_POSTFIX  0
%define NEBO_PERCENT_POSTFIX      1
%define NEBO_PERCENT_FORMAT_SLOT  2

section .text

; edi=context flags. A percent token is postfix only after a completed operand.
; eax=classification, edx=typed status.
global nebo_postfix_percent_classify
nebo_postfix_percent_classify:
    xor eax, eax
    xor edx, edx
    test edi, NEBO_QCTX_FORMAT_PLACEHOLDER
    jz .not_format
    mov eax, NEBO_PERCENT_FORMAT_SLOT
    ret
.not_format:
    test edi, NEBO_QCTX_HAS_COMPLETE_OPERAND
    jz .not_postfix
    mov eax, NEBO_PERCENT_POSTFIX
    ret
.not_postfix:
    mov edx, NEBO_QUANTITY_ERR_SYNTAX
    ret

; rdi=signed exact numerator. Returns rax=numerator, rdx=100, ecx=status.
global nebo_postfix_percent_ratio
nebo_postfix_percent_ratio:
    mov rax, rdi
    mov edx, 100
    xor ecx, ecx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
