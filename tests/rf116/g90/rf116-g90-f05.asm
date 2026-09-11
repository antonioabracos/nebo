bits 64
default rel
%include "runtime/render_model.inc"
extern nebo_render_numeric_shape
global _start
section .text
_start:
    lea rdi, [rel matrix]
    lea rsi, [rel node]
    call nebo_render_numeric_shape
    test eax, eax
    jnz fail
    cmp qword [rel node + NEBO_NODE_COUNT_OFFSET], 6
    jne fail
    cmp qword [rel node + NEBO_NODE_AUX_OFFSET], 2
    jne fail
    lea rdi, [rel mismatch]
    lea rsi, [rel untouched]
    call nebo_render_numeric_shape
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
dims: dq 2, 3
values: dq 1, 2, 3, 4, 5, 6
matrix: dq values, NEBO_TYPE_MATRIX, dims, 2, 6, 0
mismatch: dq values, NEBO_TYPE_MATRIX, dims, 2, 5, 0
untouched: times NEBO_NODE_SIZE db 0xaa
section .bss
node: resb NEBO_NODE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
