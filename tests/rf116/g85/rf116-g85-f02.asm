bits 64
default rel

%include "compiler/semantic/const_binding.inc"
extern neboc_const_symbol_resolve
global _start

section .text
_start:
    lea rdi, [rel name]
    mov esi, name_len
    mov edx, 7
    lea rcx, [rel first]
    call neboc_const_symbol_resolve
    test eax, eax
    jnz fail
    lea rdi, [rel name]
    mov esi, name_len
    mov edx, 7
    lea rcx, [rel second]
    call neboc_const_symbol_resolve
    test eax, eax
    jnz fail
    mov rax, [rel first + NEBOC_CONST_SYMBOL_ID_OFFSET]
    test rax, rax
    jz fail
    cmp rax, [rel second + NEBOC_CONST_SYMBOL_ID_OFFSET]
    jne fail
    cmp qword [rel first + NEBOC_CONST_SYMBOL_KIND_OFFSET], NEBOC_BINDING_KIND_CONST
    jne fail
    cmp qword [rel first + NEBOC_CONST_SYMBOL_FLAGS_OFFSET], 3
    jne fail

    lea rdi, [rel name]
    mov esi, name_len
    mov edx, 8
    lea rcx, [rel third]
    call neboc_const_symbol_resolve
    test eax, eax
    jnz fail
    mov rax, [rel first]
    cmp rax, [rel third]
    je fail

    lea rdi, [rel ordinary]
    mov esi, ordinary_len
    mov edx, 7
    lea rcx, [rel untouched]
    call neboc_const_symbol_resolve
    cmp eax, NEBOC_CONST_NAME_NOT_ALL_CAPS
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
name: db "MAX_RETRIES"
name_len equ $ - name
ordinary: db "maxRetries"
ordinary_len equ $ - ordinary

section .bss
first: resb NEBOC_CONST_SYMBOL_SIZE
second: resb NEBOC_CONST_SYMBOL_SIZE
third: resb NEBOC_CONST_SYMBOL_SIZE

section .data
untouched: times NEBOC_CONST_SYMBOL_SIZE db 0xaa

section .note.GNU-stack noalloc noexec nowrite progbits
