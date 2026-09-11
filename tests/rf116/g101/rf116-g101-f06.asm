bits 64
default rel
global _start
extern nebo_partition_validate
extern nebo_aggregation_validate

section .text
_start:
    mov rdi, 4096
    mov rsi, 64
    mov rdx, 100000
    call nebo_partition_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 64
    mov rdx, 100000
    call nebo_partition_validate
    cmp eax, -1
    jne .fail
    mov rdi, 4096
    mov rsi, 64
    mov rdx, 100001
    call nebo_partition_validate
    cmp eax, -1
    jne .fail
    mov rdi, 4096
    mov rsi, 64
    mov rdx, 100000
    call nebo_partition_validate
    test eax, eax
    jne .fail
    mov rdi, 100000
    mov rsi, 1024
    mov rdx, 1
    call nebo_aggregation_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
