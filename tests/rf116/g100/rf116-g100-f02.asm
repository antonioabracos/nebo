bits 64
default rel
global _start
extern nebo_progress_validate
extern nebo_log_event_validate

section .text
_start:
    mov rdi, 50
    mov rsi, 100
    mov rdx, 1
    call nebo_progress_validate
    test eax, eax
    jne .fail
    mov rdi, -1
    mov rsi, 100
    mov rdx, 1
    call nebo_progress_validate
    cmp eax, -1
    jne .fail
    mov rdi, 50
    mov rsi, 100
    mov rdx, 4
    call nebo_progress_validate
    cmp eax, -1
    jne .fail
    mov rdi, 101
    mov rsi, 100
    mov rdx, 1
    call nebo_progress_validate
    cmp eax, -1
    jne .fail
    mov rdi, 50
    mov rsi, 100
    mov rdx, 1
    call nebo_progress_validate
    test eax, eax
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
