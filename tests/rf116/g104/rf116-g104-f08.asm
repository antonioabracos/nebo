bits 64
default rel
global _start
extern nebo_font_shape_validate
extern nebo_adapter_validate

section .text
_start:
    mov rdi, 128
    mov rsi, 1
    mov rdx, 4096
    call nebo_font_shape_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 4096
    call nebo_font_shape_validate
    cmp eax, -1
    jne .fail
    mov rdi, 128
    mov rsi, 1
    mov rdx, 65537
    call nebo_font_shape_validate
    cmp eax, -1
    jne .fail
    mov rdi, 128
    mov rsi, 1
    mov rdx, 4096
    call nebo_font_shape_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 0
    mov rdx, 1
    call nebo_adapter_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
