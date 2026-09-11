bits 64
default rel
%include "runtime/render_model.inc"
extern nebo_render_dynamic
global _start
section .text
_start:
    lea rdi, [rel stream]
    lea rsi, [rel node]
    call nebo_render_dynamic
    test eax, eax
    jnz fail
    cmp qword [rel node + NEBO_NODE_TYPE_OFFSET], NEBO_TYPE_STREAM
    jne fail
    cmp qword [rel node + NEBO_NODE_COUNT_OFFSET], 8
    jne fail
    lea rdi, [rel deep_tree]
    lea rsi, [rel untouched]
    call nebo_render_dynamic
    cmp eax, NEBO_RENDER_LIMIT
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
nodes: dq 1, 2, 3, 4, 5, 6, 7, 8
stream: dq nodes, NEBO_TYPE_STREAM, 8, 1, 8, 0
deep_tree: dq nodes, NEBO_TYPE_TREE, 8, NEBO_MAX_RENDER_DEPTH + 1, 0, 0
untouched: times NEBO_NODE_SIZE db 0xaa
section .bss
node: resb NEBO_NODE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
