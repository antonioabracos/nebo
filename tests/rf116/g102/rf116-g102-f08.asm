bits 64
default rel
global _start
extern nebo_export_target_validate
extern nebo_video_boundary_validate

section .text
_start:
    mov rdi, 64
    mov rsi, 1
    mov rdx, 0
    call nebo_export_target_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 0
    call nebo_export_target_validate
    cmp eax, -1
    jne .fail
    mov rdi, 64
    mov rsi, 1
    mov rdx, 2
    call nebo_export_target_validate
    cmp eax, -1
    jne .fail
    mov rdi, 64
    mov rsi, 1
    mov rdx, 0
    call nebo_export_target_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 120
    mov rdx, 1
    call nebo_video_boundary_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
