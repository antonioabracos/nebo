; Nebo Assembly — CONSOLECALL-CONSOLEOPTION-REGISTRY-E-NORMALIZACAO receiver-first ConsoleCall AST with source spans
bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "compiler/parser/console_call.inc"
global neboc_console_call_build
section .text
; rdi=input descriptor, rsi=out AST node. Atomic on any span violation.
neboc_console_call_build:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_CONSOLE_CALL_INPUT_RECEIVER_OFFSET], 0
    je .invalid
    mov r8, [rdi + NEBOC_CONSOLE_CALL_INPUT_RECEIVER_START_OFFSET]
    mov r9, [rdi + NEBOC_CONSOLE_CALL_INPUT_RECEIVER_END_OFFSET]
    mov r10, [rdi + NEBOC_CONSOLE_CALL_INPUT_METHOD_START_OFFSET]
    mov r11, [rdi + NEBOC_CONSOLE_CALL_INPUT_METHOD_END_OFFSET]
    mov rcx, [rdi + NEBOC_CONSOLE_CALL_INPUT_CALL_END_OFFSET]
    cmp r8, r9
    ja .span
    cmp r9, r10
    ja .span
    cmp r10, r11
    jae .span
    cmp r11, rcx
    ja .span
    mov rdx, [rdi + NEBOC_CONSOLE_CALL_INPUT_ARGUMENTS_OFFSET]
    test rdx, rdx
    jz .commit
    mov rax, [rdx + NEBOC_ARGUMENT_LIST_ITEMS_OFFSET]
    mov rdx, [rdx + NEBOC_ARGUMENT_LIST_COUNT_OFFSET]
.arguments:
    test rdx, rdx
    jz .commit
    mov r11, rax
    cmp qword [r11 + NEBOC_ARGUMENT_NODE_SPAN_START_OFFSET], r10
    jb .span
    mov r11, [r11 + NEBOC_ARGUMENT_NODE_SPAN_END_OFFSET]
    cmp r11, rcx
    ja .span
    add rax, NEBOC_ARGUMENT_NODE_SIZE
    dec rdx
    jmp .arguments
.commit:
    mov rax, [rdi + NEBOC_CONSOLE_CALL_INPUT_RECEIVER_OFFSET]
    mov [rsi + NEBOC_CONSOLE_CALL_NODE_RECEIVER_OFFSET], rax
    mov rax, [rdi + NEBOC_CONSOLE_CALL_INPUT_ARGUMENTS_OFFSET]
    mov [rsi + NEBOC_CONSOLE_CALL_NODE_ARGUMENTS_OFFSET], rax
    mov [rsi + NEBOC_CONSOLE_CALL_NODE_SPAN_START_OFFSET], r8
    mov [rsi + NEBOC_CONSOLE_CALL_NODE_SPAN_END_OFFSET], rcx
    mov [rsi + NEBOC_CONSOLE_CALL_NODE_METHOD_START_OFFSET], r10
    mov rax, [rdi + NEBOC_CONSOLE_CALL_INPUT_METHOD_END_OFFSET]
    mov [rsi + NEBOC_CONSOLE_CALL_NODE_METHOD_END_OFFSET], rax
    mov qword [rsi + NEBOC_CONSOLE_CALL_NODE_STATE_OFFSET], NEBOC_CONSOLE_CALL_NODE_READY
    xor eax, eax
    ret
.span:
    mov eax, NEBOC_CONSOLE_CALL_SPAN_ORDER
    ret
.invalid:
    mov eax, NEBOC_CONSOLE_CALL_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
