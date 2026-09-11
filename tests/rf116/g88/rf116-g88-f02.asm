bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_roles.inc"
extern nebo_color_role_define
global _start
section .text
_start:
    mov edi, NEBO_ROLE_ACCENT
    mov esi, 0xff8800ff
    lea rdx, [rel accent]
    call nebo_color_role_define
    test eax, eax
    jnz fail
    cmp qword [rel accent + NEBO_ROLE_DESC_KIND_OFFSET], NEBO_ROLE_ACCENT
    jne fail
    cmp dword [rel accent + NEBO_ROLE_DESC_COLOR_OFFSET], 0xff8800ff
    jne fail
    mov edi, NEBO_ROLE_MAX + 1
    xor esi, esi
    lea rdx, [rel untouched]
    call nebo_color_role_define
    cmp eax, NEBO_COLOR_INVALID
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .bss
accent: resb NEBO_ROLE_DESC_SIZE
section .data
untouched: times NEBO_ROLE_DESC_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
