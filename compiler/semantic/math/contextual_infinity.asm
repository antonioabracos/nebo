bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_INFINITY_CONTEXT_FLOAT64   1
%define NEBO_INFINITY_CONTEXT_INTERVAL  2

section .text

; edi=context, esi=sign (0 positive, nonzero negative).
; rax=IEEE-754 binary64 bits, edx=status. Integer contexts are rejected.
global nebo_contextual_infinity_f64
nebo_contextual_infinity_f64:
    cmp edi, NEBO_INFINITY_CONTEXT_FLOAT64
    je .allowed
    cmp edi, NEBO_INFINITY_CONTEXT_INTERVAL
    jne .domain
.allowed:
    mov rax, 0x7ff0000000000000
    test esi, esi
    jz .ok
    bts rax, 63
.ok:
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret

; rdi=binary64 bits. eax=1 only for positive/negative infinity.
global nebo_is_infinity_f64_bits
nebo_is_infinity_f64_bits:
    mov rax, rdi
    shl rax, 1
    mov rcx, 0xffe0000000000000
    cmp rax, rcx
    sete al
    movzx eax, al
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
