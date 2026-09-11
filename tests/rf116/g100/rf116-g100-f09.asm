bits 64
default rel
global _start
extern nebo_cancellation_validate
extern nebo_metric_validate

section .text
_start:
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    call nebo_cancellation_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 0
    call nebo_cancellation_validate
    cmp eax, -1
    jne .fail
    mov rdi, 2
    mov rsi, 1
    mov rdx, 256
    call nebo_cancellation_validate
    cmp eax, -1
    jne .fail
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    call nebo_cancellation_validate
    test eax, eax
    jne .fail
    mov rdi, 8
    mov rsi, 2
    mov rdx, 1
    call nebo_metric_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
