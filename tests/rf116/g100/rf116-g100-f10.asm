bits 64
default rel
global _start
extern nebo_stream_contract_validate
extern nebo_cancellation_validate

section .text
_start:
    mov rdi, 1024
    mov rsi, 128
    mov rdx, 8
    call nebo_stream_contract_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 128
    mov rdx, 8
    call nebo_stream_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1024
    mov rsi, 128
    mov rdx, 65
    call nebo_stream_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 64
    mov rsi, 128
    mov rdx, 8
    call nebo_stream_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1024
    mov rsi, 128
    mov rdx, 8
    call nebo_stream_contract_validate
    test eax, eax
    jne .fail
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    call nebo_cancellation_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
