bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_CONSTANT_PI       1
%define NEBO_CONSTANT_E        2
%define NEBO_PRECISION_F64     64

section .text

; edi=constant id, esi=explicit precision. rax=IEEE-754 bits, edx=status.
global nebo_precision_constant_bits
nebo_precision_constant_bits:
    cmp esi, NEBO_PRECISION_F64
    jne .precision
    cmp edi, NEBO_CONSTANT_PI
    je .pi
    cmp edi, NEBO_CONSTANT_E
    jne .domain
    mov rax, 0x4005bf0a8b145769  ; correctly rounded e
    xor edx, edx
    ret
.pi:
    mov rax, 0x400921fb54442d18  ; correctly rounded pi
    xor edx, edx
    ret
.precision:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_PRECISION
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
