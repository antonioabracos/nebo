bits 64
default rel

%include "compiler/semantic/const_binding.inc"
%include "compiler/codegen/const_binding.inc"
%include "runtime/const_binding.inc"
extern neboc_const_symbol_resolve
extern neboc_const_codegen_materialize
extern nebo_const_load
global _start

section .text
_start:
    lea rdi, [rel name]
    mov esi, name_len
    mov edx, 1
    lea rcx, [rel symbol]
    call neboc_const_symbol_resolve
    test eax, eax
    jnz fail
    lea rdi, [rel symbol]
    mov esi, 0x10203040
    mov edx, NEBOC_CONST_STORAGE_MODULE_RODATA
    lea rcx, [rel storage]
    call neboc_const_codegen_materialize
    test eax, eax
    jnz fail
    cmp qword [rel storage + NEBOC_CONST_STORAGE_CLASS_OFFSET], NEBOC_CONST_STORAGE_MODULE_RODATA
    jne fail
    lea rdi, [rel storage]
    lea rsi, [rel loaded]
    call nebo_const_load
    test eax, eax
    jnz fail
    cmp qword [rel loaded], 0x10203040
    jne fail

    lea rdi, [rel symbol]
    mov esi, 7
    mov edx, 99
    lea rcx, [rel untouched]
    call neboc_const_codegen_materialize
    cmp eax, NEBOC_CONST_INVALID_ARGUMENT
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
name: db "COLOR_LIMIT"
name_len equ $ - name
section .bss
symbol: resb NEBOC_CONST_SYMBOL_SIZE
storage: resb NEBOC_CONST_STORAGE_SIZE
loaded: resq 1
section .data
untouched: times NEBOC_CONST_STORAGE_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
