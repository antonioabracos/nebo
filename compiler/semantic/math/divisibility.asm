bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=dividend, rsi=divisor. eax=boolean, edx=status.
global nebo_divisible_i64
nebo_divisible_i64:
    test rsi, rsi
    jz .domain
    mov r8, 0x8000000000000000
    cmp rdi, r8
    jne .divide
    cmp rsi, -1
    je .true                         ; mathematically divisible; no quotient needed
.divide:
    mov rax, rdi
    cqo
    idiv rsi
    test rdx, rdx
    sete al
    movzx eax, al
    xor edx, edx
    ret
.true:
    mov eax, 1
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret

global nebo_not_divisible_i64
nebo_not_divisible_i64:
    sub rsp, 8
    call nebo_divisible_i64
    add rsp, 8
    test edx, edx
    jnz .done
    xor eax, 1
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
