bits 64
default rel

%include "compiler/semantic/const_binding.inc"
%include "compiler/semantic/module_const.inc"
extern neboc_const_symbol_resolve
extern neboc_module_const_validate
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
    mov esi, NEBOC_MODULE_INIT_REQUIRED
    mov edx, 255
    lea rcx, [rel module_value]
    call neboc_module_const_validate
    test eax, eax
    jnz fail
    cmp qword [rel module_value + NEBOC_MODULE_CONST_VALUE_OFFSET], 255
    jne fail

    lea rdi, [rel symbol]
    mov esi, NEBOC_MODULE_INIT_PURE | NEBOC_MODULE_INIT_DETERMINISTIC
    mov edx, 1
    lea rcx, [rel untouched]
    call neboc_module_const_validate
    cmp eax, NEBOC_CONST_NOT_COMPILE_TIME
    jne fail
    lea rdi, [rel symbol]
    mov esi, NEBOC_MODULE_INIT_REQUIRED | NEBOC_MODULE_INIT_EFFECTFUL
    mov edx, 1
    lea rcx, [rel untouched]
    call neboc_module_const_validate
    cmp eax, NEBOC_CONST_EFFECTFUL_INITIALIZER
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
name: db "DEFAULT_ALPHA"
name_len equ $ - name
section .bss
symbol: resb NEBOC_CONST_SYMBOL_SIZE
module_value: resb NEBOC_MODULE_CONST_SIZE
section .data
untouched: times NEBOC_MODULE_CONST_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
