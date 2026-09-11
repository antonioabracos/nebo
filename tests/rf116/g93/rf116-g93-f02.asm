bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_cell_place
global _start
section .text
_start:
    lea rdi, [rel cell]
    lea rsi, [rel result]
    call nebo_layout_cell_place
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_CELL_LINEAR_OFFSET], 6
    jne fail
    lea rdi, [rel overflowing_span]
    lea rsi, [rel untouched]
    call nebo_layout_cell_place
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
cell: dq 2, 1, 1, 2, 2, 1, 4, 4, 0, 0
overflowing_span: dq 2, 1, 3, 2, 2, 1, 4, 4, 0, 0
untouched: times nebo_layout_model_CELL_SIZE db 0xaa
section .bss
result: resb nebo_layout_model_CELL_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
