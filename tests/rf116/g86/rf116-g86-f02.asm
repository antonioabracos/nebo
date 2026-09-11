bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "compiler/semantic/console_calls.inc"
extern neboc_console_option_resolve
global _start
section .text
_start:
    lea rdi, [rel nested]
    lea rsi, [rel resolved]
    call neboc_console_option_resolve
    test eax, eax
    jnz fail
    cmp qword [rel resolved + NEBOC_RESOLVED_OPTION_ARGUMENT_COUNT_OFFSET], 2
    jne fail
    cmp qword [rel resolved + NEBOC_RESOLVED_OPTION_DEPTH_OFFSET], 3
    jne fail
    cmp qword [rel resolved + NEBOC_RESOLVED_OPTION_SPAN_START_OFFSET], 10
    jne fail
    lea rdi, [rel too_many]
    lea rsi, [rel untouched]
    call neboc_console_option_resolve
    cmp eax, NEBOC_OPTION_ARGUMENT_LIMIT
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
name: db "fg"
name_len equ $ - name
args: dq 11, 22
section .data
nested:
    dq name, name_len, args, 2, 3, 10, 28, 0
too_many:
    dq name, name_len, args, NEBOC_MAX_OPTION_ARGUMENTS + 1, 1, 0, 2, 0
untouched: times NEBOC_RESOLVED_OPTION_SIZE db 0xaa
section .bss
resolved: resb NEBOC_RESOLVED_OPTION_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
