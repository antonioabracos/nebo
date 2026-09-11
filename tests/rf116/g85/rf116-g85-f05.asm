bits 64
default rel

%include "compiler/semantic/const_binding.inc"
%include "compiler/parser/const_compat.inc"
extern neboc_const_parse_classify
global _start

section .text
_start:
    mov edi, NEBOC_CONST_SYNTAX_EXPLICIT
    lea rsi, [rel ordinary]
    mov edx, ordinary_len
    lea rcx, [rel explicit_result]
    call neboc_const_parse_classify
    test eax, eax
    jnz fail
    cmp qword [rel explicit_result + NEBOC_CONST_PARSE_KIND_OFFSET], NEBOC_BINDING_KIND_CONST
    jne fail
    cmp qword [rel explicit_result + NEBOC_CONST_PARSE_COMPAT_OFFSET], NEBOC_CONST_COMPAT_EXPLICIT
    jne fail

    mov edi, NEBOC_CONST_SYNTAX_FLOW
    lea rsi, [rel caps]
    mov edx, caps_len
    lea rcx, [rel flow_result]
    call neboc_const_parse_classify
    test eax, eax
    jnz fail
    cmp qword [rel flow_result + NEBOC_CONST_PARSE_KIND_OFFSET], NEBOC_BINDING_KIND_CONST
    jne fail
    cmp qword [rel flow_result + NEBOC_CONST_PARSE_COMPAT_OFFSET], NEBOC_CONST_COMPAT_PREFERRED_FLOW
    jne fail

    mov edi, NEBOC_CONST_SYNTAX_FLOW
    lea rsi, [rel ordinary]
    mov edx, ordinary_len
    lea rcx, [rel ordinary_result]
    call neboc_const_parse_classify
    test eax, eax
    jnz fail
    cmp qword [rel ordinary_result + NEBOC_CONST_PARSE_KIND_OFFSET], NEBOC_BINDING_KIND_ORDINARY
    jne fail

    mov edi, 99
    lea rsi, [rel caps]
    mov edx, caps_len
    lea rcx, [rel untouched]
    call neboc_const_parse_classify
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
ordinary: db "timeout"
ordinary_len equ $ - ordinary
caps: db "DEFAULT_TIMEOUT"
caps_len equ $ - caps
section .bss
explicit_result: resb NEBOC_CONST_PARSE_SIZE
flow_result: resb NEBOC_CONST_PARSE_SIZE
ordinary_result: resb NEBOC_CONST_PARSE_SIZE
section .data
untouched: times NEBOC_CONST_PARSE_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
