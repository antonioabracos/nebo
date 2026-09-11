bits 64
default rel
%include "runtime/color_palette.inc"
extern nebo_palette_validate
extern nebo_palette_lookup
global _start
section .text
_start:
    lea rdi, [rel palette]
    mov esi, 2
    call nebo_palette_validate
    test eax, eax
    jnz fail
    lea rdi, [rel palette]
    mov esi, 2
    lea rdx, [rel ocean]
    mov ecx, 5
    lea r8, [rel result]
    call nebo_palette_lookup
    test eax, eax
    jnz fail
    cmp dword [rel result], 0x1479ffff
    jne fail
    lea rdi, [rel duplicates]
    mov esi, 2
    call nebo_palette_validate
    cmp eax, NEBO_PALETTE_DUPLICATE
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
ocean: db "ocean"
ember: db "ember"
palette:
    dq ocean, 5
    dd 0x1479ffff, 0
    dq ember, 5
    dd 0xe04422ff, 0
duplicates:
    dq ocean, 5
    dd 0x111111ff, 0
    dq ocean, 5
    dd 0x222222ff, 0
section .bss
result: resd 1
section .data
untouched: dd 0xaaaaaaaa
section .note.GNU-stack noalloc noexec nowrite progbits
