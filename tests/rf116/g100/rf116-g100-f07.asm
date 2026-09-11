bits 64
default rel
global _start
extern nebo_window_validate
extern nebo_backpressure_validate

section .text
_start:
    mov rdi, 1000
    mov rsi, 60000
    mov rdx, 2
    call nebo_window_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 60000
    mov rdx, 2
    call nebo_window_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1000
    mov rsi, 60000
    mov rdx, 4
    call nebo_window_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1000
    mov rsi, 60000
    mov rdx, 2
    call nebo_window_validate
    test eax, eax
    jne .fail
    mov rdi, 64
    mov rsi, 128
    mov rdx, 1
    call nebo_backpressure_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
