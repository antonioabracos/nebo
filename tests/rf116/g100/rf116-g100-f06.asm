bits 64
default rel
global _start
extern nebo_backpressure_validate
extern nebo_timeline_validate

section .text
_start:
    mov rdi, 64
    mov rsi, 128
    mov rdx, 1
    call nebo_backpressure_validate
    test eax, eax
    jne .fail
    mov rdi, -1
    mov rsi, 128
    mov rdx, 1
    call nebo_backpressure_validate
    cmp eax, -1
    jne .fail
    mov rdi, 64
    mov rsi, 128
    mov rdx, 2
    call nebo_backpressure_validate
    cmp eax, -1
    jne .fail
    mov rdi, 129
    mov rsi, 128
    mov rdx, 1
    call nebo_backpressure_validate
    cmp eax, -1
    jne .fail
    mov rdi, 64
    mov rsi, 128
    mov rdx, 1
    call nebo_backpressure_validate
    test eax, eax
    jne .fail
    mov rdi, 100
    mov rsi, 1
    mov rdx, 1
    call nebo_timeline_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
