bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi/rsi and rdx/rcx are two signed rationals. eax=equivalent, edx=status.
global nebo_rational_equivalent_i64
nebo_rational_equivalent_i64:
    test rsi, rsi
    jz .domain
    test rcx, rcx
    jz .domain
    mov r8, rdi
    imul r8, rcx
    jo .overflow
    mov r9, rdx
    imul r9, rsi
    jo .overflow
    cmp r8, r9
    sete al
    movzx eax, al
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

; Pairs (rdi,rsi) and (rdx,rcx) are proportional when cross-products match.
global nebo_pair_proportional_i64
nebo_pair_proportional_i64:
    mov r8, rdi
    or r8, rsi
    jz .domain
    mov r8, rdx
    or r8, rcx
    jz .domain
    mov r8, rdi
    imul r8, rcx
    jo .overflow
    mov r9, rsi
    imul r9, rdx
    jo .overflow
    cmp r8, r9
    sete al
    movzx eax, al
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
