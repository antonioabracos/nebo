bits 64
default rel
global _start
extern nebo_timeline_validate
extern nebo_parallel_validate

section .text
_start:
    mov rdi, 100
    mov rsi, 1
    mov rdx, 1
    call nebo_timeline_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 1
    call nebo_timeline_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100
    mov rsi, 1
    mov rdx, 4
    call nebo_timeline_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100
    mov rsi, 1
    mov rdx, 1
    call nebo_timeline_validate
    test eax, eax
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_parallel_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
