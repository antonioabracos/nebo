bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "compiler/parser/console_call.inc"
extern neboc_console_call_build
global _start
section .text
_start:
    lea rdi, [rel input]
    lea rsi, [rel node]
    call neboc_console_call_build
    test eax, eax
    jnz fail
    lea rax, [rel receiver]
    cmp [rel node + NEBOC_CONSOLE_CALL_NODE_RECEIVER_OFFSET], rax
    jne fail
    cmp qword [rel node + NEBOC_CONSOLE_CALL_NODE_SPAN_START_OFFSET], 10
    jne fail
    mov qword [rel input + NEBOC_CONSOLE_CALL_INPUT_METHOD_START_OFFSET], 9
    lea rdi, [rel input]
    lea rsi, [rel untouched]
    call neboc_console_call_build
    cmp eax, NEBOC_CONSOLE_CALL_SPAN_ORDER
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
receiver: dq 0x434f4e534f4c45
align 8
input:
    dq receiver, 10, 17, 18, 23, 0, 25
section .bss
node: resb NEBOC_CONSOLE_CALL_NODE_SIZE
section .data
untouched: times NEBOC_CONSOLE_CALL_NODE_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
