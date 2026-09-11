bits 64
default rel
global _start
extern nebo_adapter_validate
extern nebo_window_target_validate

section .text
_start:
    mov rdi, 1
    mov rsi, 0
    mov rdx, 1
    call nebo_adapter_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 0
    mov rdx, 1
    call nebo_adapter_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 0
    mov rdx, 2
    call nebo_adapter_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 0
    mov rdx, 1
    call nebo_adapter_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 0
    mov rdx, 1
    call nebo_window_target_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
