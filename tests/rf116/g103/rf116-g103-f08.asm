bits 64
default rel
global _start
extern nebo_capability_report_validate
extern nebo_roundtrip_validate

section .text
_start:
    mov rdi, 8
    mov rsi, 1
    mov rdx, 1
    call nebo_capability_report_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 1
    call nebo_capability_report_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 1
    mov rdx, 2
    call nebo_capability_report_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 1
    mov rdx, 1
    call nebo_capability_report_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 1
    mov rdx, 8
    call nebo_roundtrip_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
