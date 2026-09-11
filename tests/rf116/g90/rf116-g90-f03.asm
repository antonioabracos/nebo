bits 64
default rel
%include "runtime/render_model.inc"
extern nebo_render_collection
global _start
section .text
_start:
    lea rdi, [rel list_value]
    lea rsi, [rel node]
    call nebo_render_collection
    test eax, eax
    jnz fail
    cmp qword [rel node + NEBO_NODE_KIND_OFFSET], NEBO_NODE_COLLECTION
    jne fail
    cmp qword [rel node + NEBO_NODE_COUNT_OFFSET], 3
    jne fail
    lea rdi, [rel unbounded]
    lea rsi, [rel untouched]
    call nebo_render_collection
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
items: dq 1, 2, 3
list_value: dq NEBO_TYPE_LIST, items, 3, 0
unbounded: dq NEBO_TYPE_OBJECT, items, NEBO_MAX_RENDER_NODES + 1, 0
untouched: times NEBO_NODE_SIZE db 0xaa
section .bss
node: resb NEBO_NODE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
