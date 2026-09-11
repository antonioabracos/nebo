bits 64
default rel
global _start
extern nebo_protocol_contract_validate
extern nebo_security_validate

section .text
_start:
    mov rdi, 64
    mov rsi, 4096
    mov rdx, 1
    call nebo_protocol_contract_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 4096
    mov rdx, 1
    call nebo_protocol_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 64
    mov rsi, 4096
    mov rdx, 2
    call nebo_protocol_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 64
    mov rsi, 4096
    mov rdx, 1
    call nebo_protocol_contract_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 1
    mov rdx, 1
    call nebo_security_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
