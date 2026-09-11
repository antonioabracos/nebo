bits 64
default rel
%include "runtime/style_tokens.inc"
%include "runtime/color_target.inc"
extern nebo_style_font_resolve
global _start
section .text
_start:
    lea rdi, [rel headless_font]
    lea rsi, [rel result]
    call nebo_style_font_resolve
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_FONT_APPLIED_ID_OFFSET], 0
    jne fail
    cmp qword [rel result + NEBO_FONT_FALLBACK_OFFSET], NEBO_FONT_FALLBACK_TARGET_DEFAULT
    jne fail
    lea rdi, [rel unsupported_live]
    lea rsi, [rel untouched]
    call nebo_style_font_resolve
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
headless_font: dq 7, 16, NEBO_COLOR_TARGET_HEADLESS, 0
    times 4 dq 0
unsupported_live: dq 7, 16, NEBO_COLOR_TARGET_LIVE, 0
    times 4 dq 0
untouched: times NEBO_FONT_SIZE db 0xaa
section .bss
result: resb NEBO_FONT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
