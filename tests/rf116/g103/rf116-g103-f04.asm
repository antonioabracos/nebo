bits 64
default rel
global _start
extern nebo_visual_event_validate
extern nebo_table_event_validate

section .text
_start:
    mov rdi, 3
    mov rsi, 64
    mov rdx, 1
    call nebo_visual_event_validate
    test eax, eax
    jne .fail
    mov rdi, 2
    mov rsi, 64
    mov rdx, 1
    call nebo_visual_event_validate
    cmp eax, -1
    jne .fail
    mov rdi, 3
    mov rsi, 64
    mov rdx, 2
    call nebo_visual_event_validate
    cmp eax, -1
    jne .fail
    mov rdi, 3
    mov rsi, 64
    mov rdx, 1
    call nebo_visual_event_validate
    test eax, eax
    jne .fail
    mov rdi, 2
    mov rsi, 32
    mov rdx, 8
    call nebo_table_event_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
