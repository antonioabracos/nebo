bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=value A, rsi=value B, rdx=explicit non-negative tolerance.
; eax=boolean, edx=status. No default or implicit tolerance exists.
global nebo_approx_equal_i64
nebo_approx_equal_i64:
    mov r8, rdx
    test r8, r8
    js .domain
    mov rax, rdi
    sub rax, rsi
    jo .overflow
    test rax, rax
    jns .compare
    neg rax
    jo .overflow
.compare:
    cmp rax, r8
    setbe al
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
