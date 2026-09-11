bits 64
default rel
global _start
extern nebo_animation_plan_validate
extern nebo_large_data_contract_validate

section .text
_start:
    mov rdi, 1
    mov rsi, 4
    mov rdx, 1
    call nebo_animation_plan_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 4
    mov rdx, 1
    call nebo_animation_plan_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 4
    mov rdx, 4
    call nebo_animation_plan_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 4
    mov rdx, 1
    call nebo_animation_plan_validate
    test eax, eax
    jne .fail
    mov rdi, 100000
    mov rsi, 67108864
    mov rdx, 1024
    call nebo_large_data_contract_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
