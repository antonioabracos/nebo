default rel
section .text
global nebo_partial_central_i64
; rdi=f(x+h), rsi=f(x-h), rdx=h>0; rax=derivative, rdx=status.
nebo_partial_central_i64:
    test rdx, rdx
    jle .domain
    mov rcx, rdx
    add rcx, rcx
    jo .overflow
    mov rax, rdi
    sub rax, rsi
    jo .overflow
    cqo
    idiv rcx
    xor edx, edx
    ret
.domain: xor eax, eax
    mov edx, 1
    ret
.overflow: xor eax, eax
    mov edx, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
