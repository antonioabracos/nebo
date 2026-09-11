bits 64
default rel
%include "compiler/semantic/color.inc"
%include "compiler/semantic/color_options.inc"
%include "runtime/color_options.inc"
extern neboc_color_option_typecheck
extern nebo_color_option_materialize
global _start
section .text
_start:
    mov edi, NEBOC_COLOR_ROLE_FOREGROUND
    mov esi, NEBOC_COLOR_TYPE_ID
    mov edx, 0x112233ff
    lea rcx, [rel typed]
    call neboc_color_option_typecheck
    test eax, eax
    jnz fail
    lea rdi, [rel typed]
    lea rsi, [rel runtime]
    call nebo_color_option_materialize
    test eax, eax
    jnz fail
    cmp dword [rel runtime + NEBO_COLOR_RUNTIME_OPTION_VALUE_OFFSET], 0x112233ff
    jne fail
    xor edi, edi
    mov esi, NEBOC_COLOR_TYPE_ID
    mov edx, 0x112233ff
    lea rcx, [rel untouched]
    call neboc_color_option_typecheck
    cmp eax, NEBOC_COLOR_OPTION_BARE_COLOR
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
typed: resb NEBOC_COLOR_OPTION_SIZE
runtime: resb NEBO_COLOR_RUNTIME_OPTION_SIZE
section .data
untouched: times NEBOC_COLOR_OPTION_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
