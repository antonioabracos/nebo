bits 64
default rel
%include "runtime/style_tokens.inc"
extern nebo_style_accessibility_validate
global _start
section .text
_start:
    lea rdi, [rel accessible]
    lea rsi, [rel result]
    call nebo_style_accessibility_validate
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_A11Y_NAME_LENGTH_OFFSET], 4
    jne fail
    cmp qword [rel result + NEBO_A11Y_STATE_OFFSET], NEBO_A11Y_READY
    jne fail
    lea rdi, [rel private]
    lea rsi, [rel untouched]
    call nebo_style_accessibility_validate
    cmp eax, NEBO_STYLE_PRIVACY
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
name_text: db "load"
description_text: db "current load"
section .data
accessible: dq 3, name_text, 4, description_text, 12, 1, 0, 0
private: dq 3, name_text, 4, description_text, 12, 1, NEBO_A11Y_SENSITIVE, 0
untouched: times NEBO_A11Y_SIZE db 0xaa
section .bss
result: resb NEBO_A11Y_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
