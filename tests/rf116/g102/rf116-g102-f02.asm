bits 64
default rel
global _start
extern nebo_timebase_validate
extern nebo_animation_plan_validate

section .text
_start:
    mov rdi, 120
    mov rsi, 1000
    mov rdx, 1
    call nebo_timebase_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1000
    mov rdx, 1
    call nebo_timebase_validate
    cmp eax, -1
    jne .fail
    mov rdi, 120
    mov rsi, 1000
    mov rdx, 2
    call nebo_timebase_validate
    cmp eax, -1
    jne .fail
    mov rdi, 120
    mov rsi, 1000
    mov rdx, 1
    call nebo_timebase_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 4
    mov rdx, 1
    call nebo_animation_plan_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
