bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=signed numerator, rsi=positive denominator. rax=floor, edx=status.
global nebo_floor_rational_i64
nebo_floor_rational_i64:
    test rsi, rsi
    jle .domain
    mov rax, rdi
    cqo
    idiv rsi
    test rdx, rdx
    jz .ok
    test rdi, rdi
    jns .ok
    dec rax
.ok:
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret

; rdi=signed numerator, rsi=positive denominator. rax=ceil, edx=status.
global nebo_ceil_rational_i64
nebo_ceil_rational_i64:
    test rsi, rsi
    jle .domain
    mov rax, rdi
    cqo
    idiv rsi
    test rdx, rdx
    jz .ok
    test rdi, rdi
    js .ok
    inc rax
.ok:
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
