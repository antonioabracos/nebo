; Nebo Assembly — CHAMADAS-ANINHADAS-EM-CONSOLE-E-AVALIACAO-EXACTLY-ONCE Console call composition codegen boundary
bits 64
default rel
%include "compiler/semantic/console_calls.inc"
%include "compiler/lowering/console_calls.inc"
%include "compiler/codegen/console_calls.inc"
global neboc_console_call_codegen
section .text
; rdi=receiver value, rsi=evaluation plan, rdx=out ConsoleCall descriptor.
; This stage builds a plan only; it never renders output.
neboc_console_call_codegen:
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp qword [rsi + NEBOC_EVALUATION_PLAN_STATE_OFFSET], NEBOC_EVALUATION_PLAN_READY
    jne .invalid
    mov [rdx + NEBOC_CONSOLE_CALL_RECEIVER_OFFSET], rdi
    mov rax, [rsi + NEBOC_EVALUATION_PLAN_VALUES_OFFSET]
    mov [rdx + NEBOC_CONSOLE_CALL_OPTIONS_OFFSET], rax
    mov rax, [rsi + NEBOC_EVALUATION_PLAN_COUNT_OFFSET]
    mov [rdx + NEBOC_CONSOLE_CALL_OPTION_COUNT_OFFSET], rax
    mov rax, [rsi + NEBOC_EVALUATION_PLAN_STEPS_OFFSET]
    mov [rdx + NEBOC_CONSOLE_CALL_EVALUATION_STEPS_OFFSET], rax
    mov qword [rdx + NEBOC_CONSOLE_CALL_STATE_OFFSET], NEBOC_CONSOLE_CALL_READY
    xor eax, eax
    ret
.invalid:
    mov eax, NEBOC_OPTION_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
