bits 64
default rel
global _start
extern nebo_trust_zones_validate

section .text
_start:
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_trust_zones_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 4
    mov rdx, 1
    call nebo_trust_zones_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 4
    call nebo_trust_zones_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_trust_zones_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
