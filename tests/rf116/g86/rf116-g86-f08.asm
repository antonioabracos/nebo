bits 64
default rel
%include "compiler/lowering/console_calls.inc"
%include "compiler/codegen/console_calls.inc"
extern neboc_console_options_evaluate
extern neboc_console_call_codegen
global _start
section .text
_start:
    lea rdi, [rel evaluators]
    mov esi, 2
    lea rdx, [rel values]
    lea rcx, [rel evaluation]
    call neboc_console_options_evaluate
    test eax, eax
    jnz fail
    mov edi, 0x1234
    lea rsi, [rel evaluation]
    lea rdx, [rel call]
    call neboc_console_call_codegen
    test eax, eax
    jnz fail
    cmp qword [rel call + NEBOC_CONSOLE_CALL_RECEIVER_OFFSET], 0x1234
    jne fail
    cmp qword [rel call + NEBOC_CONSOLE_CALL_OPTION_COUNT_OFFSET], 2
    jne fail
    lea rsi, [rel invalid_plan]
    lea rdx, [rel untouched]
    call neboc_console_call_codegen
    test eax, eax
    jz fail
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
eval_a: xor eax, eax
    mov edx, 7
    ret
eval_b: xor eax, eax
    mov edx, 9
    ret
section .rodata
evaluators: dq eval_a, 0, 0, eval_b, 0, 0
invalid_plan: times 4 dq 0
section .bss
values: resq 2
evaluation: resb NEBOC_EVALUATION_PLAN_SIZE
call: resb NEBOC_CONSOLE_CALL_SIZE
section .data
untouched: times NEBOC_CONSOLE_CALL_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
