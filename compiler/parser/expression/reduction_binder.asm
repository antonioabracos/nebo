bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_SUM       1
%define NEBO_REDUCTION_PRODUCT   2
%define NEBO_REDUCTION_MAX_COUNT 1048576

section .text

; edi=Unicode scalar, esi=context, rdx=finite element count.
; eax=operation kind, edx=status. Empty domains are valid with explicit identity.
global nebo_reduction_binder_classify
nebo_reduction_binder_classify:
    mov r8, rdx
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_SYNTAX
    test esi, NEBO_QCTX_DOMAIN_ENABLED
    jz .done
    cmp r8, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    cmp edi, 0x2211                    ; N-ARY SUMMATION
    je .sum
    cmp edi, 0x220f                    ; N-ARY PRODUCT
    jne .done
    mov eax, NEBO_REDUCTION_PRODUCT
    xor edx, edx
    ret
.sum:
    mov eax, NEBO_REDUCTION_SUM
    xor edx, edx
    ret
.domain:
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
