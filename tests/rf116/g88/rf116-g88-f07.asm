bits 64
default rel
%include "runtime/color_space.inc"
extern nebo_color_space_normalize
global _start
section .text
_start:
    mov edi, NEBO_SPACE_LINEAR_SRGB16
    mov esi, 65535
    mov edx, 32768
    xor ecx, ecx
    mov r8d, 65535
    lea r9, [rel normalized]
    call nebo_color_space_normalize
    test eax, eax
    jnz fail
    cmp qword [rel normalized + NEBO_SPACE_DESC_C1_OFFSET], 65535
    jne fail
    mov edi, NEBO_SPACE_GRAY8
    mov esi, 128
    mov edx, 1
    xor ecx, ecx
    mov r8d, 255
    lea r9, [rel untouched]
    call nebo_color_space_normalize
    cmp eax, NEBO_SPACE_BOUNDARY
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
normalized: resb NEBO_SPACE_DESC_SIZE
section .data
untouched: times NEBO_SPACE_DESC_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
