bits 64
default rel
global _start
extern nebo_large_data_contract_validate
extern nebo_performance_report_validate

section .text
_start:
    mov rdi, 100000
    mov rsi, 67108864
    mov rdx, 1024
    call nebo_large_data_contract_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 67108864
    mov rdx, 1024
    call nebo_large_data_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100000
    mov rsi, 67108864
    mov rdx, 1025
    call nebo_large_data_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100000
    mov rsi, 67108864
    mov rdx, 1024
    call nebo_large_data_contract_validate
    test eax, eax
    jne .fail
    mov rdi, 100000
    mov rsi, 10
    mov rdx, 2
    call nebo_performance_report_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
