bits 64
default rel
global _start
extern nebo_budget_validate
extern nebo_cache_validate

section .text
_start:
    mov rdi, 67108864
    mov rsi, 16
    mov rdx, 2
    call nebo_budget_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 16
    mov rdx, 2
    call nebo_budget_validate
    cmp eax, -1
    jne .fail
    mov rdi, 67108864
    mov rsi, 16
    mov rdx, 5
    call nebo_budget_validate
    cmp eax, -1
    jne .fail
    mov rdi, 67108864
    mov rsi, 16
    mov rdx, 2
    call nebo_budget_validate
    test eax, eax
    jne .fail
    mov rdi, 256
    mov rsi, 1
    mov rdx, 1
    call nebo_cache_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
