bits 64
default rel

%include "compiler/semantic/const_binding.inc"
%include "compiler/lowering/const_binding.inc"
extern neboc_const_symbol_resolve
extern neboc_const_lower_local
global _start

section .text
_start:
    lea rdi, [rel name]
    mov esi, name_len
    mov edx, 19
    lea rcx, [rel symbol]
    call neboc_const_symbol_resolve
    test eax, eax
    jnz fail

    lea rdi, [rel symbol]
    lea rsi, [rel initializer]
    lea rdx, [rel success_count]
    lea rcx, [rel local]
    call neboc_const_lower_local
    test eax, eax
    jnz fail
    cmp qword [rel success_count], 1
    jne fail
    cmp qword [rel local + NEBOC_CONST_LOCAL_VALUE_OFFSET], 42
    jne fail
    cmp qword [rel local + NEBOC_CONST_LOCAL_EVALUATION_COUNT_OFFSET], 1
    jne fail
    cmp qword [rel local + NEBOC_CONST_LOCAL_STATE_OFFSET], NEBOC_CONST_LOCAL_INITIALIZED
    jne fail

    lea rdi, [rel symbol]
    lea rsi, [rel failing_initializer]
    lea rdx, [rel failure_count]
    lea rcx, [rel untouched]
    call neboc_const_lower_local
    cmp eax, NEBOC_CONST_INITIALIZER_FAILED
    jne fail
    cmp qword [rel failure_count], 1
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

initializer:
    inc qword [rdi]
    xor eax, eax
    mov edx, 42
    ret

failing_initializer:
    inc qword [rdi]
    mov eax, 1
    mov edx, 99
    ret

section .rodata
name: db "ANSWER"
name_len equ $ - name

section .bss
symbol: resb NEBOC_CONST_SYMBOL_SIZE
local: resb NEBOC_CONST_LOCAL_SIZE
success_count: resq 1
failure_count: resq 1

section .data
untouched: times NEBOC_CONST_LOCAL_SIZE db 0xaa

section .note.GNU-stack noalloc noexec nowrite progbits
