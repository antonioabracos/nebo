; Nebo Assembly — CHAMADAS-ANINHADAS-EM-CONSOLE-E-AVALIACAO-EXACTLY-ONCE semantic resolution of nested Console options
bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "compiler/semantic/console_calls.inc"
global neboc_console_option_resolve
global neboc_console_factory_validate
section .text
; rdi=option expression, rsi=out resolved option. Atomic on failure.
neboc_console_option_resolve:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov rax, [rdi + NEBOC_OPTION_EXPR_NAME_OFFSET]
    test rax, rax
    jz .invalid
    cmp qword [rdi + NEBOC_OPTION_EXPR_NAME_LENGTH_OFFSET], 0
    je .invalid
    mov rax, [rdi + NEBOC_OPTION_EXPR_ARGUMENT_COUNT_OFFSET]
    cmp rax, NEBOC_MAX_OPTION_ARGUMENTS
    ja .arguments
    test rax, rax
    jz .arguments_ok
    cmp qword [rdi + NEBOC_OPTION_EXPR_ARGUMENTS_OFFSET], 0
    je .invalid
.arguments_ok:
    mov rax, [rdi + NEBOC_OPTION_EXPR_DEPTH_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, NEBOC_MAX_NESTED_CALL_DEPTH
    ja .depth
    mov rax, [rdi + NEBOC_OPTION_EXPR_SPAN_START_OFFSET]
    cmp rax, [rdi + NEBOC_OPTION_EXPR_SPAN_END_OFFSET]
    ja .invalid
    mov rax, [rdi + NEBOC_OPTION_EXPR_NAME_OFFSET]
    mov [rsi + NEBOC_RESOLVED_OPTION_NAME_OFFSET], rax
    mov rax, [rdi + NEBOC_OPTION_EXPR_ARGUMENTS_OFFSET]
    mov [rsi + NEBOC_RESOLVED_OPTION_ARGUMENTS_OFFSET], rax
    mov rax, [rdi + NEBOC_OPTION_EXPR_ARGUMENT_COUNT_OFFSET]
    mov [rsi + NEBOC_RESOLVED_OPTION_ARGUMENT_COUNT_OFFSET], rax
    mov rax, [rdi + NEBOC_OPTION_EXPR_DEPTH_OFFSET]
    mov [rsi + NEBOC_RESOLVED_OPTION_DEPTH_OFFSET], rax
    mov rax, [rdi + NEBOC_OPTION_EXPR_SPAN_START_OFFSET]
    mov [rsi + NEBOC_RESOLVED_OPTION_SPAN_START_OFFSET], rax
    mov rax, [rdi + NEBOC_OPTION_EXPR_SPAN_END_OFFSET]
    mov [rsi + NEBOC_RESOLVED_OPTION_SPAN_END_OFFSET], rax
    mov qword [rsi + NEBOC_RESOLVED_OPTION_STATE_OFFSET], NEBOC_RESOLVED_OPTION_VALID
    xor eax, eax
    ret
.arguments:
    mov eax, NEBOC_OPTION_ARGUMENT_LIMIT
    ret
.depth:
    mov eax, NEBOC_OPTION_DEPTH_LIMIT
    ret
.invalid:
    mov eax, NEBOC_OPTION_INVALID
    ret

; rdi=factory descriptor, rsi=out boundedness proof.
neboc_console_factory_validate:
    test rdi, rdi
    jz .factory_invalid
    test rsi, rsi
    jz .factory_invalid
    cmp qword [rdi + NEBOC_FACTORY_FUNCTION_OFFSET], 0
    je .factory_invalid
    mov rax, [rdi + NEBOC_FACTORY_MAX_INVOCATIONS_OFFSET]
    test rax, rax
    jz .factory_unbounded
    cmp rax, NEBOC_MAX_CONSOLE_OPTIONS
    ja .factory_unbounded
    mov rcx, [rdi + NEBOC_FACTORY_MAX_STEPS_OFFSET]
    test rcx, rcx
    jz .factory_unbounded
    cmp rcx, NEBOC_MAX_OPTION_BUILD_STEPS
    ja .factory_unbounded
    mov rdx, [rdi + NEBOC_FACTORY_MAX_DEPTH_OFFSET]
    test rdx, rdx
    jz .factory_unbounded
    cmp rdx, NEBOC_MAX_NESTED_CALL_DEPTH
    ja .factory_unbounded
    mov [rsi + NEBOC_FACTORY_PROOF_INVOCATIONS_OFFSET], rax
    mov [rsi + NEBOC_FACTORY_PROOF_STEPS_OFFSET], rcx
    mov [rsi + NEBOC_FACTORY_PROOF_DEPTH_OFFSET], rdx
    xor eax, eax
    ret
.factory_unbounded:
    mov eax, NEBOC_OPTION_FACTORY_UNBOUNDED
    ret
.factory_invalid:
    mov eax, NEBOC_OPTION_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
