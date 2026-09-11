bits 64
default rel
%include "runtime/style_tokens.inc"
%include "runtime/color_roles.inc"
extern nebo_style_status_validate
global _start
section .text
_start:
    lea rdi, [rel warning]
    lea rsi, [rel result]
    call nebo_style_status_validate
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_STATUS_KIND_OFFSET], NEBO_STATUS_WARN
    jne fail
    cmp qword [rel result + NEBO_STATUS_FALLBACK_CHAR_OFFSET], '!'
    jne fail
    lea rdi, [rel color_only]
    lea rsi, [rel untouched]
    call nebo_style_status_validate
    cmp eax, NEBO_STYLE_ACCESSIBILITY
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
section .rodata
warning_text: db "warning"
section .data
warning: dq NEBO_STATUS_WARN, warning_text, 7, '!', NEBO_ROLE_ACCENT, 0
color_only: dq NEBO_STATUS_ERROR, 0, 0, '!', NEBO_ROLE_ACCENT, 0
untouched: times NEBO_STATUS_SIZE db 0xaa
section .bss
result: resb NEBO_STATUS_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
