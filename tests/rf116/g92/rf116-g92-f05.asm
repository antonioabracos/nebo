bits 64
default rel
%include "runtime/style_tokens.inc"
%include "runtime/color_target.inc"
extern nebo_style_colors_validate
global _start
section .text
_start:
    lea rdi, [rel colors]
    lea rsi, [rel result]
    call nebo_style_colors_validate
    test eax, eax
    jnz fail
    mov eax, 0xffffffff
    cmp qword [rel result + NEBO_STYLE_COLORS_FOREGROUND_OFFSET], rax
    jne fail
    lea rdi, [rel alpha_without_capability]
    lea rsi, [rel untouched]
    call nebo_style_colors_validate
    cmp eax, NEBO_STYLE_TARGET
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
colors: dq 0xffffffff, 0x101820ff, 0x00ff00ff, 7, NEBO_COLOR_TARGET_ANSI, NEBO_COLOR_CAP_TRUECOLOR, 0
alpha_without_capability: dq 0xffffff80, 0, 0, NEBO_STYLE_COLOR_FOREGROUND, NEBO_COLOR_TARGET_ANSI, 0, 0
untouched: times NEBO_STYLE_COLORS_SIZE db 0xaa
section .bss
result: resb NEBO_STYLE_COLORS_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
