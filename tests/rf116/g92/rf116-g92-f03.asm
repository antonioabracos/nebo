bits 64
default rel
%include "runtime/style_tokens.inc"
extern nebo_style_registry_validate
global _start
section .text
_start:
    lea rdi, [rel registry]
    lea rsi, [rel receipt]
    call nebo_style_registry_validate
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_STYLE_REGISTRY_RECEIPT_COUNT_OFFSET], 2
    jne fail
    lea rdi, [rel duplicate_registry]
    lea rsi, [rel untouched]
    call nebo_style_registry_validate
    cmp eax, NEBO_STYLE_CONFLICT
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
tokens:
    dq 1, NEBO_STYLE_BOLD, 0, 1
    dq 2, NEBO_STYLE_UNDERLINE, NEBO_STYLE_DIM, 2
duplicate_tokens:
    dq 1, NEBO_STYLE_BOLD, 0, 1
    dq 1, NEBO_STYLE_ITALIC, 0, 2
registry: dq tokens, 2
duplicate_registry: dq duplicate_tokens, 2
untouched: times NEBO_STYLE_REGISTRY_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_STYLE_REGISTRY_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
