bits 64
default rel
global _start
extern nebo_decimation_validate
extern nebo_lod_validate

section .text
_start:
    mov rdi, 100000
    mov rsi, 10000
    mov rdx, 1
    call nebo_decimation_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 10000
    mov rdx, 1
    call nebo_decimation_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100000
    mov rsi, 10000
    mov rdx, 4
    call nebo_decimation_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1000
    mov rsi, 2000
    mov rdx, 1
    call nebo_decimation_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100000
    mov rsi, 10000
    mov rdx, 1
    call nebo_decimation_validate
    test eax, eax
    jne .fail
    mov rdi, 4
    mov rsi, 100000
    mov rdx, 1
    call nebo_lod_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
