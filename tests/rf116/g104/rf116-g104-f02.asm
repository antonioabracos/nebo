bits 64
default rel
global _start
extern nebo_headless_backend_validate
extern nebo_backend_registry_validate

section .text
_start:
    mov rdi, 2
    mov rsi, 3
    mov rdx, 1
    call nebo_headless_backend_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 3
    mov rdx, 1
    call nebo_headless_backend_validate
    cmp eax, -1
    jne .fail
    mov rdi, 2
    mov rsi, 3
    mov rdx, 2
    call nebo_headless_backend_validate
    cmp eax, -1
    jne .fail
    mov rdi, 2
    mov rsi, 3
    mov rdx, 1
    call nebo_headless_backend_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 1
    mov rdx, 1
    call nebo_backend_registry_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
