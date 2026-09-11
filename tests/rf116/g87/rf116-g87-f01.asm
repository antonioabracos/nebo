bits 64
default rel
%include "runtime/color.inc"
%include "compiler/semantic/color.inc"
extern neboc_color_type_descriptor
extern nebo_color_copy
global _start
section .text
_start:
    lea rdi, [rel descriptor]
    call neboc_color_type_descriptor
    test eax, eax
    jnz fail
    cmp qword [rel descriptor + NEBOC_COLOR_DESC_TYPE_ID_OFFSET], NEBOC_COLOR_TYPE_ID
    jne fail
    cmp qword [rel descriptor + NEBOC_COLOR_DESC_SIZE_OFFSET], 4
    jne fail
    cmp qword [rel descriptor + NEBOC_COLOR_DESC_ALIGN_OFFSET], 4
    jne fail
    mov edi, 0x12345678
    lea rsi, [rel copied]
    call nebo_color_copy
    test eax, eax
    jnz fail
    cmp dword [rel copied], 0x12345678
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .bss
descriptor: resb NEBOC_COLOR_DESC_SIZE
copied: resd 1
section .note.GNU-stack noalloc noexec nowrite progbits
