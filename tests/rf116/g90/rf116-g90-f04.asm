bits 64
default rel
%include "runtime/render_model.inc"
extern nebo_render_tabular
global _start
section .text
_start:
    lea rdi, [rel table]
    lea rsi, [rel node]
    call nebo_render_tabular
    test eax, eax
    jnz fail
    cmp qword [rel node + NEBO_NODE_COUNT_OFFSET], 2
    jne fail
    cmp qword [rel node + NEBO_NODE_AUX_OFFSET], 2
    jne fail
    lea rdi, [rel no_schema]
    lea rsi, [rel untouched]
    call nebo_render_tabular
    cmp eax, NEBO_RENDER_SCHEMA
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
cells: dq 1, 2, 3, 4
schema: dq 2
table: dq cells, NEBO_TYPE_TABLE, 2, 2, schema, 0
no_schema: dq cells, NEBO_TYPE_DATASET, 2, 2, 0, 0
untouched: times NEBO_NODE_SIZE db 0xaa
section .bss
node: resb NEBO_NODE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
