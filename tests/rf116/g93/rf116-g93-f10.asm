bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_tree_validate
global _start
section .text
_start:
    lea rdi, [rel tree]
    lea rsi, [rel receipt]
    call nebo_layout_tree_validate
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_LAYOUT_TREE_RECEIPT_NODE_COUNT_OFFSET], 3
    jne fail
    cmp qword [rel receipt + NEBO_LAYOUT_TREE_RECEIPT_EDGE_COUNT_OFFSET], 2
    jne fail
    lea rdi, [rel cyclic_tree]
    lea rsi, [rel untouched]
    call nebo_layout_tree_validate
    cmp eax, NEBO_LAYOUT_CYCLE
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
    dq NEBO_LAYOUT_GRID, 1, 0, 2, 80, 24, 0, NEBO_LAYOUT_NODE_READY
    dq NEBO_LAYOUT_ROW, 2, 0, 0, 40, 12, 0, NEBO_LAYOUT_NODE_READY
    dq NEBO_LAYOUT_COLUMN, 3, 0, 0, 40, 12, 0, NEBO_LAYOUT_NODE_READY
edges: dq 1, 2, 1, 3
cyclic_edges: dq 2, 1, 1, 3
tree: dq nodes, 3, edges, 2, 1, 2
cyclic_tree: dq nodes, 3, cyclic_edges, 2, 1, 2
untouched: times NEBO_LAYOUT_TREE_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_LAYOUT_TREE_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
