bits 64
default rel
global _start
extern nebo_metric_validate
extern nebo_window_validate

section .text
_start:
    mov rdi, 8
    mov rsi, 2
    mov rdx, 1
    call nebo_metric_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 2
    mov rdx, 1
    call nebo_metric_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 2
    mov rdx, 9
    call nebo_metric_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 2
    mov rdx, 1
    call nebo_metric_validate
    test eax, eax
    jne .fail
    mov rdi, 1000
    mov rsi, 60000
    mov rdx, 2
    call nebo_window_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
