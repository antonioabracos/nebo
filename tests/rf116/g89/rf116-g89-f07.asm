bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "runtime/console_options.inc"
extern nebo_console_options_budget_check
global _start
section .text
_start:
    lea rdi, [rel maximum]
    lea rsi, [rel accepted]
    call nebo_console_options_budget_check
    test eax, eax
    jnz fail
    cmp qword [rel accepted + NEBOC_BUDGET_STEPS_OFFSET], NEBOC_MAX_OPTION_BUILD_STEPS
    jne fail
    lea rdi, [rel excessive]
    lea rsi, [rel untouched]
    call nebo_console_options_budget_check
    cmp eax, NEBO_OPTIONS_BUDGET_OPTIONS
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
maximum:
    dq NEBOC_MAX_CONSOLE_OPTIONS
    dq NEBOC_MAX_OPTION_ARGUMENTS
    dq NEBOC_MAX_NESTED_CALL_DEPTH
    dq NEBOC_MAX_OPTION_AST_NODES
    dq NEBOC_MAX_OPTION_BUILD_STEPS
excessive:
    dq NEBOC_MAX_CONSOLE_OPTIONS + 1, 0, 0, 0, 0
section .bss
accepted: resb neboc_console_arguments_BUDGET_SIZE
section .data
untouched: times neboc_console_arguments_BUDGET_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
