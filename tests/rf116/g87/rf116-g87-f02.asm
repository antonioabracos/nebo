bits 64
default rel
%include "runtime/color.inc"
extern nebo_color_rgb_lowering
extern nebo_color_rgba_lowering
global _start
section .text
_start:
    mov edi, 0x12
    mov esi, 0x34
    mov edx, 0x56
    lea rcx, [rel rgb]
    call nebo_color_rgb_lowering
    test eax, eax
    jnz fail
    cmp dword [rel rgb], 0x123456ff
    jne fail
    xor edi, edi
    mov esi, 255
    mov edx, 128
    mov ecx, 64
    lea r8, [rel rgba]
    call nebo_color_rgba_lowering
    test eax, eax
    jnz fail
    cmp dword [rel rgba], 0x00ff8040
    jne fail
    mov edi, 256
    xor esi, esi
    xor edx, edx
    lea rcx, [rel untouched]
    call nebo_color_rgb_lowering
    cmp eax, NEBO_COLOR_CHANNEL_RANGE
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
section .bss
rgb: resd 1
rgba: resd 1
section .data
untouched: dd 0xaaaaaaaa
section .note.GNU-stack noalloc noexec nowrite progbits
