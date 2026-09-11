bits 64
default rel
global _start
extern nebo_window_target_validate
extern nebo_event_loop_validate

section .text
_start:
    mov rdi, 1
    mov rsi, 0
    mov rdx, 1
    call nebo_window_target_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 0
    mov rdx, 1
    call nebo_window_target_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 0
    mov rdx, 17
    call nebo_window_target_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 0
    mov rdx, 1
    call nebo_window_target_validate
    test eax, eax
    jne .fail
    mov rdi, 100
    mov rsi, 1
    mov rdx, 1
    call nebo_event_loop_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
