bits 64
default rel
%include "runtime/color.inc"
extern nebo_color_hex_literal
global _start
section .text
_start:
    lea rdi, [rel six]
    mov esi, six_len
    lea rdx, [rel first]
    call nebo_color_hex_literal
    test eax, eax
    jnz fail
    cmp dword [rel first], 0xff0080ff
    jne fail
    lea rdi, [rel eight]
    mov esi, eight_len
    lea rdx, [rel second]
    call nebo_color_hex_literal
    test eax, eax
    jnz fail
    cmp dword [rel second], 0x12abcdef
    jne fail
    lea rdi, [rel invalid]
    mov esi, invalid_len
    lea rdx, [rel untouched]
    call nebo_color_hex_literal
    cmp eax, NEBO_COLOR_HEX_INVALID
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
six: db "#FF0080"
six_len equ $ - six
eight: db "#12abcDEF"
eight_len equ $ - eight
invalid: db "#GG0000"
invalid_len equ $ - invalid
section .bss
first: resd 1
second: resd 1
section .data
untouched: dd 0xaaaaaaaa
section .note.GNU-stack noalloc noexec nowrite progbits
