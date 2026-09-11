bits 64
default rel
global _start
extern nebo_event_loop_validate
extern nebo_frame_validate

section .text
_start:
    mov rdi, 100
    mov rsi, 1
    mov rdx, 1
    call nebo_event_loop_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 1
    call nebo_event_loop_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100
    mov rsi, 1
    mov rdx, 2
    call nebo_event_loop_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100
    mov rsi, 1
    mov rdx, 0
    call nebo_event_loop_validate
    cmp eax, -1
    jne .fail
    mov rdi, 100
    mov rsi, 1
    mov rdx, 1
    call nebo_event_loop_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 42
    mov rdx, 1
    call nebo_frame_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
