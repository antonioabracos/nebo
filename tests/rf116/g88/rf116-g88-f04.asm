bits 64
default rel
%include "runtime/color_theme.inc"
%include "runtime/color.inc"
extern nebo_theme_resolve
global _start
section .text
_start:
    lea rdi, [rel theme]
    mov esi, NEBO_THEME_TOKEN_ACCENT
    lea rdx, [rel output]
    call nebo_theme_resolve
    test eax, eax
    jnz fail
    cmp dword [rel output], 0xffffffff
    jne fail
    lea rdi, [rel theme]
    mov esi, NEBO_THEME_TOKEN_BACKGROUND
    lea rdx, [rel output]
    call nebo_theme_resolve
    test eax, eax
    jnz fail
    cmp dword [rel output], 0x101820ff
    jne fail
    lea rdi, [rel theme]
    xor esi, esi
    lea rdx, [rel untouched]
    call nebo_theme_resolve
    cmp eax, NEBO_COLOR_INVALID
    jne fail
    cmp dword [rel untouched], 0xaaaaaaaa
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .data
align 8
theme:
    dd 0xffffffff, 0x101820ff, 0xff6600ff, 0x667788ff, 0x334455ff, 0x22aa77ff
    dq 0
    dq NEBO_THEME_VALID
output: dd 0
untouched: dd 0xaaaaaaaa
section .note.GNU-stack noalloc noexec nowrite progbits
