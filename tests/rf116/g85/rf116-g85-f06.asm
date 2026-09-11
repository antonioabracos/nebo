bits 64
default rel

%include "compiler/semantic/const_binding.inc"
extern neboc_const_symbol_resolve
extern neboc_const_validate_action
extern neboc_const_check_visible_collision
global _start

section .text
_start:
    lea rdi, [rel name]
    mov esi, name_len
    mov edx, 3
    lea rcx, [rel visible]
    call neboc_const_symbol_resolve
    test eax, eax
    jnz fail
    lea rdi, [rel name]
    mov esi, name_len
    mov edx, 4
    lea rcx, [rel candidate]
    call neboc_const_symbol_resolve
    test eax, eax
    jnz fail

    lea rdi, [rel visible]
    mov esi, NEBOC_CONST_ACTION_READ
    call neboc_const_validate_action
    test eax, eax
    jnz fail
    lea rdi, [rel visible]
    mov esi, NEBOC_CONST_ACTION_WRITE
    call neboc_const_validate_action
    cmp eax, NEBOC_CONST_WRITE_FORBIDDEN
    jne fail
    lea rdi, [rel visible]
    mov esi, NEBOC_CONST_ACTION_MARK_MUTABLE
    call neboc_const_validate_action
    cmp eax, NEBOC_CONST_WRITE_FORBIDDEN
    jne fail

    lea rdi, [rel visible]
    mov esi, 1
    lea rdx, [rel candidate]
    call neboc_const_check_visible_collision
    cmp eax, NEBOC_CONST_SHADOW_FORBIDDEN
    jne fail

    lea rdi, [rel other_name]
    mov esi, other_name_len
    mov edx, 4
    lea rcx, [rel other]
    call neboc_const_symbol_resolve
    test eax, eax
    jnz fail
    lea rdi, [rel visible]
    mov esi, 1
    lea rdx, [rel other]
    call neboc_const_check_visible_collision
    test eax, eax
    jnz fail

    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall

section .rodata
name: db "MAX_RETRIES"
name_len equ $ - name
other_name: db "DEFAULT_TIMEOUT"
other_name_len equ $ - other_name
section .bss
visible: resb NEBOC_CONST_SYMBOL_SIZE
candidate: resb NEBOC_CONST_SYMBOL_SIZE
other: resb NEBOC_CONST_SYMBOL_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
