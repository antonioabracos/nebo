; Nebo Assembly — CHAMADAS-ANINHADAS-EM-CONSOLE-E-AVALIACAO-EXACTLY-ONCE left-to-right exactly-once option lowering
bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "compiler/semantic/console_calls.inc"
%include "compiler/lowering/console_calls.inc"
global neboc_console_options_evaluate
section .text
; rdi=evaluator records, rsi=count, rdx=out values[count], rcx=out plan.
; evaluator(ctx) returns eax status and rdx value. No output is committed until
; every evaluator succeeds in source order.
neboc_console_options_evaluate:
    test rcx, rcx
    jz .invalid
    cmp rsi, NEBOC_MAX_CONSOLE_OPTIONS
    ja .limit
    test rsi, rsi
    jz .empty
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, NEBOC_MAX_CONSOLE_OPTIONS * 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    xor r15d, r15d
.evaluate:
    cmp r15, r12
    jae .publish
    mov rax, r15
    imul rax, NEBOC_EVALUATOR_SIZE
    mov rdx, [rbx + rax + NEBOC_EVALUATOR_FUNCTION_OFFSET]
    test rdx, rdx
    jz .failed
    mov rdi, [rbx + rax + NEBOC_EVALUATOR_CONTEXT_OFFSET]
    call rdx
    test eax, eax
    jnz .failed
    mov [rsp + r15 * 8], rdx
    inc r15
    jmp .evaluate
.publish:
    xor r8d, r8d
.copy:
    cmp r8, r12
    jae .plan
    mov rax, [rsp + r8 * 8]
    mov [r13 + r8 * 8], rax
    inc r8
    jmp .copy
.plan:
    mov [r14 + NEBOC_EVALUATION_PLAN_VALUES_OFFSET], r13
    mov [r14 + NEBOC_EVALUATION_PLAN_COUNT_OFFSET], r12
    mov [r14 + NEBOC_EVALUATION_PLAN_STEPS_OFFSET], r12
    mov qword [r14 + NEBOC_EVALUATION_PLAN_STATE_OFFSET], NEBOC_EVALUATION_PLAN_READY
    xor eax, eax
    jmp .done
.failed:
    mov eax, NEBOC_OPTION_EVALUATION_FAILED
.done:
    add rsp, NEBOC_MAX_CONSOLE_OPTIONS * 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.empty:
    mov qword [rcx + NEBOC_EVALUATION_PLAN_VALUES_OFFSET], 0
    mov qword [rcx + NEBOC_EVALUATION_PLAN_COUNT_OFFSET], 0
    mov qword [rcx + NEBOC_EVALUATION_PLAN_STEPS_OFFSET], 0
    mov qword [rcx + NEBOC_EVALUATION_PLAN_STATE_OFFSET], NEBOC_EVALUATION_PLAN_READY
    xor eax, eax
    ret
.limit:
    mov eax, NEBOC_CONSOLE_ARGS_TOO_MANY
    ret
.invalid:
    mov eax, NEBOC_OPTION_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
