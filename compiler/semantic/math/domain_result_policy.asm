bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_MATH_RESULT_VALUE       0
%define NEBO_MATH_RESULT_DOMAIN      1
%define NEBO_MATH_RESULT_OVERFLOW    2
%define NEBO_MATH_RESULT_PRECISION   3
%define NEBO_MATH_RESULT_TYPE        4

section .text

; edi=primitive status. eax=public typed result variant, edx=status.
; Failures remain data; this layer never substitutes a sentinel numeric value.
global nebo_math_domain_result_variant
nebo_math_domain_result_variant:
    xor edx, edx
    test edi, edi
    jz .value
    cmp edi, NEBO_QUANTITY_ERR_DOMAIN
    je .domain
    cmp edi, NEBO_QUANTITY_ERR_OVERFLOW
    je .overflow
    cmp edi, NEBO_QUANTITY_ERR_PRECISION
    je .precision
    cmp edi, NEBO_QUANTITY_ERR_UNIT
    je .type
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    xor eax, eax
    ret
.value:
    mov eax, NEBO_MATH_RESULT_VALUE
    ret
.domain:
    mov eax, NEBO_MATH_RESULT_DOMAIN
    ret
.overflow:
    mov eax, NEBO_MATH_RESULT_OVERFLOW
    ret
.precision:
    mov eax, NEBO_MATH_RESULT_PRECISION
    ret
.type:
    mov eax, NEBO_MATH_RESULT_TYPE
    ret

; eax=1 only when a domain-gated operator may be bound in this context.
global nebo_math_domain_gate_enabled
nebo_math_domain_gate_enabled:
    mov eax, edi
    and eax, NEBO_QCTX_DOMAIN_ENABLED
    setnz al
    movzx eax, al
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
