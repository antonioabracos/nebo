bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; edi=Unicode scalar, esi=context. eax=unit, rdx=exact denominator, ecx=status.
global nebo_postfix_ratio_unit
nebo_postfix_ratio_unit:
    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    mov r8d, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_DOMAIN_ENABLED
    and esi, r8d
    cmp esi, r8d
    jne .syntax_error
    cmp edi, 0x2030                 ; PER MILLE SIGN
    je .per_mille
    cmp edi, 0x2031                 ; PER TEN THOUSAND SIGN
    je .basis_points
.syntax_error:
    mov ecx, NEBO_QUANTITY_ERR_SYNTAX
    ret
.per_mille:
    mov eax, NEBO_UNIT_PER_MILLE
    mov edx, 1000
    ret
.basis_points:
    mov eax, NEBO_UNIT_BASIS_POINTS
    mov edx, 10000
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
