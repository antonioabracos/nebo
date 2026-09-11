bits 64
default rel
%include "runtime/structured_views.inc"
extern nebo_table_view_build
global _start
section .text
_start:
    lea rdi, [rel table]
    lea rsi, [rel receipt]
    call nebo_table_view_build
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_TABLE_RECEIPT_CELLS_OFFSET], 24
    jne fail
    cmp qword [rel receipt + NEBO_TABLE_RECEIPT_GENERATION_OFFSET], 9
    jne fail
    lea rdi, [rel oversized]
    lea rsi, [rel untouched]
    call nebo_table_view_build
    cmp eax, NEBO_VIEW_LIMIT
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
source: dq 11, 12, 13
schema: dq 1, 2, 3
table: dq source, schema, 8, 3, 9
oversized: dq source, schema, 33, 1, 9
untouched: times NEBO_TABLE_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_TABLE_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
