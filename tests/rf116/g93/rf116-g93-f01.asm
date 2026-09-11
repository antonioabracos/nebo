bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_container_build
global _start
section .text
_start:
    lea rdi, [rel grid]
    lea rsi, [rel result]
    call nebo_layout_container_build
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_GRID
    jne fail
    cmp qword [rel result + NEBO_LAYOUT_NODE_CHILD_COUNT_OFFSET], 2
    jne fail
    lea rdi, [rel unbounded]
    lea rsi, [rel untouched]
    call nebo_layout_container_build
    cmp eax, NEBO_LAYOUT_LIMIT
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
children: dq 2, 3
grid: dq NEBO_LAYOUT_GRID, 1, children, 2, 80, 24, 0, 0
unbounded: dq NEBO_LAYOUT_ROW, 2, children, NEBO_LAYOUT_MAX_NODES + 1, 80, 24, 0, 0
untouched: times NEBO_LAYOUT_NODE_SIZE db 0xaa
section .bss
result: resb NEBO_LAYOUT_NODE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
