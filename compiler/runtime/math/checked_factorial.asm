bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=n. Unsigned 64-bit factorial is defined exactly for 0..20.
; rax=result, edx=status.
global nebo_factorial_u64_checked
nebo_factorial_u64_checked:
    cmp rdi, 20
    ja .domain
    mov eax, 1
    mov ecx, 2
.loop:
    cmp rcx, rdi
    ja .done
    mul rcx
    test rdx, rdx
    jnz .overflow
    inc rcx
    jmp .loop
.done:
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
