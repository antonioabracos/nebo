bits 64
default rel
%include "runtime/color.inc"
%include "compiler/lowering/color.inc"
extern neboc_color_sugar_lower
global _start
section .text
_start:
    lea rdi, [rel rgb_request]
    lea rsi, [rel rgb]
    call neboc_color_sugar_lower
    test eax, eax
    jnz fail
    cmp dword [rel rgb], 0x010203ff
    jne fail
    lea rdi, [rel rgba_request]
    lea rsi, [rel rgba]
    call neboc_color_sugar_lower
    test eax, eax
    jnz fail
    cmp dword [rel rgba], 0x01020304
    jne fail
    lea rdi, [rel hex_request]
    lea rsi, [rel hex]
    call neboc_color_sugar_lower
    test eax, eax
    jnz fail
    cmp dword [rel hex], 0x010203ff
    jne fail
    lea rdi, [rel invalid_request]
    lea rsi, [rel untouched]
    call neboc_color_sugar_lower
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
section .rodata
rgb_args: dq 1, 2, 3
rgba_args: dq 1, 2, 3, 4
hex_text: db "#010203"
hex_len equ $ - hex_text
rgb_request: dq NEBOC_COLOR_SUGAR_RGB, rgb_args, 3, 0, 0
rgba_request: dq NEBOC_COLOR_SUGAR_RGBA, rgba_args, 4, 0, 0
hex_request: dq NEBOC_COLOR_SUGAR_HEX, 0, 1, hex_text, hex_len
invalid_request: dq 99, 0, 0, 0, 0
section .bss
rgb: resd 1
rgba: resd 1
hex: resd 1
section .data
untouched: dd 0xaaaaaaaa
section .note.GNU-stack noalloc noexec nowrite progbits
