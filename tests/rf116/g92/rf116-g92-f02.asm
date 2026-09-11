bits 64
default rel
%include "runtime/style_tokens.inc"
extern nebo_style_optional_effects
global _start
section .text
_start:
    mov edi, NEBO_STYLE_DIM | NEBO_STYLE_BLINK
    mov esi, NEBO_STYLE_CAP_DIM
    lea rdx, [rel fragment]
    call nebo_style_optional_effects
    test eax, eax
    jnz fail
    cmp qword [rel fragment + NEBO_STYLE_FRAGMENT_VALUE_OFFSET], NEBO_STYLE_DIM
    jne fail
    cmp qword [rel fragment + NEBO_STYLE_FRAGMENT_AUX_OFFSET], NEBO_STYLE_BLINK
    jne fail
    mov edi, 64
    xor esi, esi
    lea rdx, [rel untouched]
    call nebo_style_optional_effects
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
