bits 64
default rel
%include "runtime/style_tokens.inc"
extern nebo_style_core_decorations
global _start
section .text
_start:
    mov edi, NEBO_STYLE_BOLD | NEBO_STYLE_UNDERLINE
    lea rsi, [rel fragment]
    call nebo_style_core_decorations
    test eax, eax
    jnz fail
    cmp qword [rel fragment + NEBO_STYLE_FRAGMENT_VALUE_OFFSET], 5
    jne fail
    mov edi, 8
    lea rsi, [rel untouched]
    call nebo_style_core_decorations
    cmp eax, NEBO_STYLE_INVALID
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
section .data
untouched: times NEBO_STYLE_FRAGMENT_SIZE db 0xaa
section .bss
fragment: resb NEBO_STYLE_FRAGMENT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
