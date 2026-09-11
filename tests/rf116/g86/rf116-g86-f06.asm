bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "compiler/semantic/console_calls.inc"
extern neboc_console_budget_validate
global _start
section .text
_start:
    mov edi, NEBOC_MAX_CONSOLE_OPTIONS
    mov esi, NEBOC_MAX_OPTION_ARGUMENTS
    mov edx, NEBOC_MAX_NESTED_CALL_DEPTH
    mov ecx, NEBOC_MAX_OPTION_AST_NODES
    mov r8d, NEBOC_MAX_OPTION_BUILD_STEPS
    lea r9, [rel accepted]
    call neboc_console_budget_validate
    test eax, eax
    jnz fail
    cmp qword [rel accepted + NEBOC_BUDGET_STEPS_OFFSET], NEBOC_MAX_OPTION_BUILD_STEPS
    jne fail
    mov edi, NEBOC_MAX_CONSOLE_OPTIONS
    mov esi, NEBOC_MAX_OPTION_ARGUMENTS
    mov edx, NEBOC_MAX_NESTED_CALL_DEPTH + 1
    mov ecx, 1
    mov r8d, 1
    lea r9, [rel untouched]
    call neboc_console_budget_validate
    cmp eax, NEBOC_CONSOLE_ARGS_DEPTH
    jne fail
    mov edi, 1
    mov esi, 1
    mov edx, 1
    mov ecx, 1
    mov r8d, NEBOC_MAX_OPTION_BUILD_STEPS + 1
    lea r9, [rel untouched]
    call neboc_console_budget_validate
    cmp eax, NEBOC_CONSOLE_ARGS_STEPS
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
section .bss
accepted: resb neboc_console_arguments_BUDGET_SIZE
section .data
untouched: times neboc_console_arguments_BUDGET_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
