bits 64
default rel
global _start
extern nebo_log_event_validate

section .text
_start:
    mov rdi, 4
    mov rsi, 2
    mov rdx, 1
    call nebo_log_event_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 2
    mov rdx, 1
    call nebo_log_event_validate
    cmp eax, -1
    jne .fail
    mov rdi, 4
    mov rsi, 2
    mov rdx, 2
    call nebo_log_event_validate
    cmp eax, -1
    jne .fail
    mov rdi, 4
    mov rsi, 2
    mov rdx, 1
    call nebo_log_event_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
