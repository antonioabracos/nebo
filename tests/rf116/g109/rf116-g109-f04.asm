bits 64
default rel
global _start
extern nebo_const_binding_validate

section .text
_start:
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_const_binding_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 4
    mov rdx, 1
    call nebo_const_binding_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 9
    call nebo_const_binding_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_const_binding_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
