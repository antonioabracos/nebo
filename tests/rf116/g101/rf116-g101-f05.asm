bits 64
default rel
global _start
extern nebo_aggregation_validate
extern nebo_density_validate

section .text
_start:
    mov rdi, 100000
    mov rsi, 1024
    mov rdx, 1
    call nebo_aggregation_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1024
    mov rdx, 1
    call nebo_aggregation_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100000
    mov rsi, 1024
    mov rdx, 5
    call nebo_aggregation_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1000
    mov rsi, 2000
    mov rdx, 1
    call nebo_aggregation_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100000
    mov rsi, 1024
    mov rdx, 1
    call nebo_aggregation_validate
    test eax, eax
    jne .fail
    mov rdi, 1024
    mov rsi, 8
    mov rdx, 64
    call nebo_density_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
