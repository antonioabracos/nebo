bits 64
default rel
global _start
extern nebo_window_lifecycle_validate
extern nebo_headless_backend_validate

section .text
_start:
    mov rdi, 0
    mov rsi, 1
    mov rdx, 0
    call nebo_window_lifecycle_validate
    test eax, eax
    jne .fail
    mov rdi, -1
    mov rsi, 1
    mov rdx, 0
    call nebo_window_lifecycle_validate
    cmp eax, -1
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 2
    call nebo_window_lifecycle_validate
    cmp eax, -1
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 0
    call nebo_window_lifecycle_validate
    test eax, eax
    jne .fail
    mov rdi, 2
    mov rsi, 3
    mov rdx, 1
    call nebo_headless_backend_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
