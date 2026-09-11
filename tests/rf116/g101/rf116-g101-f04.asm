bits 64
default rel
global _start
extern nebo_density_validate
extern nebo_sampling_validate

section .text
_start:
    mov rdi, 1024
    mov rsi, 8
    mov rdx, 64
    call nebo_density_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 8
    mov rdx, 64
    call nebo_density_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1024
    mov rsi, 8
    mov rdx, 257
    call nebo_density_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1024
    mov rsi, 8
    mov rdx, 64
    call nebo_density_validate
    test eax, eax
    jne .fail
    mov rdi, 100000
    mov rsi, 4096
    mov rdx, 17
    call nebo_sampling_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
