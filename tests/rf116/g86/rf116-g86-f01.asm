bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "compiler/parser/console_call.inc"
extern neboc_console_argument_list_build
extern neboc_console_call_build
global _start
section .text
_start:
    lea rdi, [rel nodes]
    mov esi, 2
    lea rdx, [rel list]
    call neboc_console_argument_list_build
    test eax, eax
    jnz fail
    cmp qword [rel list + NEBOC_ARGUMENT_LIST_COUNT_OFFSET], 2
    jne fail
    cmp qword [rel list + NEBOC_ARGUMENT_LIST_TOTAL_NODES_OFFSET], 5
    jne fail
    cmp qword [rel list + NEBOC_ARGUMENT_LIST_MAX_DEPTH_OFFSET], 3
    jne fail
    lea rdi, [rel call_input]
    lea rsi, [rel call_node]
    call neboc_console_call_build
    test eax, eax
    jnz fail
    cmp qword [rel call_node + NEBOC_CONSOLE_CALL_NODE_RECEIVER_OFFSET], 0x1234
    jne fail
    cmp qword [rel call_node + NEBOC_CONSOLE_CALL_NODE_SPAN_END_OFFSET], 43
    jne fail
    lea rdi, [rel bad_node]
    mov esi, 1
    lea rdx, [rel untouched]
    call neboc_console_argument_list_build
    cmp eax, NEBOC_CONSOLE_ARGS_INVALID
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
section .data
nodes:
    dq NEBOC_ARGUMENT_EXPR, 1, 1, 20, 24
    dq NEBOC_ARGUMENT_OPTION_CALL, 4, 3, 26, 42
bad_node:
    dq NEBOC_ARGUMENT_EXPR, 1, 1, 9, 2
call_input:
    dq 0x1234, 0, 9, 10, 17, list, 43
untouched: times NEBOC_ARGUMENT_LIST_SIZE db 0xaa
section .bss
list: resb NEBOC_ARGUMENT_LIST_SIZE
call_node: resb NEBOC_CONSOLE_CALL_NODE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
