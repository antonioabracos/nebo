bits 64
default rel
%include "runtime/color.inc"
extern nebo_color_channels
extern nebo_color_red
extern nebo_color_green
extern nebo_color_blue
extern nebo_color_alpha
extern nebo_color_equal
extern nebo_color_hash
global _start
section .text
_start:
    mov edi, 0x12345678
    lea rsi, [rel channels]
    call nebo_color_channels
    test eax, eax
    jnz fail
    cmp dword [rel channels], 0x78563412
    jne fail
    mov edi, 0x12345678
    call nebo_color_red
    cmp eax, 0x12
    jne fail
    mov edi, 0x12345678
    call nebo_color_green
    cmp eax, 0x34
    jne fail
    mov edi, 0x12345678
    call nebo_color_blue
    cmp eax, 0x56
    jne fail
    mov edi, 0x12345678
    call nebo_color_alpha
    cmp eax, 0x78
    jne fail
    mov edi, 0x12345678
    mov esi, 0x12345678
    call nebo_color_equal
    cmp eax, 1
    jne fail
    mov edi, 0x12345678
    mov esi, 0x12345679
    call nebo_color_equal
    test eax, eax
    jnz fail
    mov edi, 0x12345678
    call nebo_color_hash
    mov [rel hash_a], rax
    mov edi, 0x12345678
    call nebo_color_hash
    cmp rax, [rel hash_a]
    jne fail
    mov edi, 0x12345679
    call nebo_color_hash
    cmp rax, [rel hash_a]
    je fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .bss
channels: resd 1
hash_a: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
