bits 64
default rel
%include "compiler/lowering/console_calls.inc"
extern neboc_console_options_evaluate
global _start
section .text
_start:
    lea rdi, [rel evaluators]
    mov esi, 3
    lea rdx, [rel values]
    lea rcx, [rel plan]
    call neboc_console_options_evaluate
    test eax, eax
    jnz fail
    cmp qword [rel phase], 3
    jne fail
    cmp qword [rel values], 10
    jne fail
    cmp qword [rel values + 8], 20
    jne fail
    cmp qword [rel values + 16], 30
    jne fail
    cmp qword [rel plan + NEBOC_EVALUATION_PLAN_STEPS_OFFSET], 3
    jne fail

    mov qword [rel phase], 0
    lea rdi, [rel failing_evaluators]
    mov esi, 3
    lea rdx, [rel untouched]
    lea rcx, [rel untouched_plan]
    call neboc_console_options_evaluate
    cmp eax, NEBOC_OPTION_EVALUATION_FAILED
    jne fail
    cmp qword [rel phase], 3
    jne fail
    cmp qword [rel cleanup_count], 2
    jne fail
    cmp qword [rel cleanup_order], 0x201
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    cmp qword [rel untouched_plan], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall

eval_1:
    cmp qword [rdi], 0
    jne callback_fail
    inc qword [rdi]
    xor eax, eax
    mov edx, 10
    ret
eval_2:
    cmp qword [rdi], 1
    jne callback_fail
    inc qword [rdi]
    xor eax, eax
    mov edx, 20
    ret
eval_3:
    cmp qword [rdi], 2
    jne callback_fail
    inc qword [rdi]
    xor eax, eax
    mov edx, 30
    ret
eval_fail:
    cmp qword [rdi], 2
    jne callback_fail
    inc qword [rdi]
    mov eax, 1
    ret
callback_fail:
    mov eax, 2
    ret
cleanup_1:
    inc qword [rel cleanup_count]
    shl qword [rel cleanup_order], 8
    or qword [rel cleanup_order], 1
    ret
cleanup_2:
    inc qword [rel cleanup_count]
    mov qword [rel cleanup_order], 2
    ret

section .data
phase: dq 0
cleanup_count: dq 0
cleanup_order: dq 0
evaluators:
    dq eval_1, phase, cleanup_1
    dq eval_2, phase, cleanup_2
    dq eval_3, phase, 0
failing_evaluators:
    dq eval_1, phase, cleanup_1
    dq eval_2, phase, cleanup_2
    dq eval_fail, phase, 0
untouched: times 3 dq 0xaaaaaaaaaaaaaaaa
untouched_plan: times 4 dq 0xaaaaaaaaaaaaaaaa
section .bss
values: resq 3
plan: resb NEBOC_EVALUATION_PLAN_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
