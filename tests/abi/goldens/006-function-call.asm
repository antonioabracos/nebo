bits 64
default rel

section .text
global nebo_fn_1
nebo_fn_1:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rdi
    mov rax, [rbp+16]
    mov [rbp-16], rax
    mov rax, 88
    push rax
    mov rax, 77
    push rax
    mov rdi, 11
    mov rsi, 22
    mov rdx, 33
    mov rcx, 44
    mov r8, 55
    mov r9, 66
    call nebo_fn_2
    add rsp, 16
    mov rax, 99
    mov rsp, rbp
    pop rbp
    ret
global nebo_fn_2
nebo_fn_2:
    push rbp
    mov rbp, rsp
    mov rax, 44
    mov rsp, rbp
    pop rbp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
