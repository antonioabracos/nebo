bits 64
default rel
global _start
extern nebo_video_boundary_validate
extern nebo_png_boundary_validate

section .text
_start:
    mov rdi, 1
    mov rsi, 120
    mov rdx, 1
    call nebo_video_boundary_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 120
    mov rdx, 1
    call nebo_video_boundary_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 120
    mov rdx, 4
    call nebo_video_boundary_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 120
    mov rdx, 1
    call nebo_video_boundary_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 1920
    mov rdx, 1080
    call nebo_png_boundary_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
