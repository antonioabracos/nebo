bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=value A, esi=unit A, rdx=value B, ecx=unit B.
; rax=sum, edx=status. Unit mismatch never produces a value.
global nebo_quantity_add_checked
nebo_quantity_add_checked:
    mov r8, rdx
    cmp esi, ecx
    jne .unit_error
    mov rax, rdi
    add rax, r8
    jo .overflow
    xor edx, edx
    ret
.unit_error:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_UNIT
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

global nebo_quantity_sub_checked
nebo_quantity_sub_checked:
    mov r8, rdx
    cmp esi, ecx
    jne .unit_error
    mov rax, rdi
    sub rax, r8
    jo .overflow
    xor edx, edx
    ret
.unit_error:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_UNIT
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

; rdi=value, rsi=numerator, rdx=denominator. Exact rescale only.
global nebo_quantity_rescale_exact
nebo_quantity_rescale_exact:
    test rdx, rdx
    jz .domain
    mov rcx, rdx
    mov rax, rdi
    imul rax, rsi
    jo .overflow
    cqo
    idiv rcx
    test rdx, rdx
    jnz .precision
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.precision:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_PRECISION
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
