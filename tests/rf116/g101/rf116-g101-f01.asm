bits 64
default rel
global _start
extern nebo_lod_validate
extern nebo_stream_contract_validate

section .text
_start:
    mov rdi, 4
    mov rsi, 100000
    mov rdx, 1
    call nebo_lod_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 100000
    mov rdx, 1
    call nebo_lod_validate
    cmp eax, -1
    jne .fail
    mov rdi, 4
    mov rsi, 100000
    mov rdx, 5
    call nebo_lod_validate
    cmp eax, -1
    jne .fail
    mov rdi, 4
    mov rsi, 100000
    mov rdx, 1
    call nebo_lod_validate
    test eax, eax
    jne .fail
    mov rdi, 1024
    mov rsi, 128
    mov rdx, 8
    call nebo_stream_contract_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
