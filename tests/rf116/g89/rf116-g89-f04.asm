bits 64
default rel
%include "runtime/console_option_registry.inc"
extern nebo_option_registry_validate_names
extern nebo_option_registry_lookup_name
global _start
section .text
_start:
    lea rdi, [rel schemas]
    mov esi, 3
    call nebo_option_registry_validate_names
    test eax, eax
    jnz fail
    lea rdi, [rel schemas]
    mov esi, 3
    lea rdx, [rel title]
    mov ecx, 5
    lea r8, [rel found]
    call nebo_option_registry_lookup_name
    test eax, eax
    jnz fail
    mov rax, [rel found]
    cmp qword [rax + NEBO_OPTION_SCHEMA_KIND_OFFSET], 2
    jne fail
    lea rdi, [rel duplicate]
    mov esi, 2
    call nebo_option_registry_validate_names
    cmp eax, NEBO_OPTION_REGISTRY_NAME_DUPLICATE
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
kind: db "kind"
title: db "title"
width: db "width"
schemas:
    dq 1, 1, 1, 0, 0, kind, 4
    dq 2, 1, 1, 0, 0, title, 5
    dq 3, 1, 1, 0, 0, width, 5
duplicate:
    dq 4, 0, 1, 0, 0, title, 5
    dq 5, 0, 1, 0, 0, title, 5
section .bss
found: resq 1
section .data
untouched: dq 0xaaaaaaaaaaaaaaaa
section .note.GNU-stack noalloc noexec nowrite progbits
