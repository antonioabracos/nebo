bits 64
default rel
%include "runtime/console_option_registry.inc"
extern nebo_option_registry_validate
extern nebo_option_registry_lookup
global _start
section .text
_start:
    lea rdi, [rel schemas]
    mov esi, 2
    call nebo_option_registry_validate
    test eax, eax
    jnz fail
    lea rdi, [rel schemas]
    mov esi, 2
    mov edx, 2
    lea rcx, [rel found]
    call nebo_option_registry_lookup
    test eax, eax
    jnz fail
    mov rax, [rel found]
    cmp qword [rax + NEBO_OPTION_SCHEMA_MAX_ARGS_OFFSET], 2
    jne fail
    lea rdi, [rel duplicate]
    mov esi, 2
    call nebo_option_registry_validate
    cmp eax, NEBO_OPTION_REGISTRY_DUPLICATE
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
schemas:
    dq 1, 1, 1, 0, 0, 0, 0
    dq 2, 1, 2, 0, 0, 0, 0
duplicate:
    dq 3, 0, 1, 0, 0, 0, 0
    dq 3, 0, 1, 0, 0, 0, 0
section .bss
found: resq 1
section .data
untouched: dq 0xaaaaaaaaaaaaaaaa
section .note.GNU-stack noalloc noexec nowrite progbits
