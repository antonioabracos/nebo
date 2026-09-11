bits 64
default rel
%include "runtime/structured_views.inc"
extern nebo_table_query_plan
global _start
section .text
_start:
    mov rax, [rel source]
    mov [rel before], rax
    lea rdi, [rel query]
    lea rsi, [rel receipt]
    call nebo_table_query_plan
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_QUERY_RECEIPT_SELECTED_CELL_OFFSET], 7
    jne fail
    mov rax, [rel before]
    cmp rax, [rel source]
    jne fail
    lea rdi, [rel bad_query]
    lea rsi, [rel untouched]
    call nebo_table_query_plan
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
source: dq 0x1122334455667788, 2, 3
filter: db 'ok'
query: dq source, 4, 3, 1, filter, 2, 2, 1, 7
bad_query: dq source, 4, 3, 3, filter, 2, 2, 1, 7
untouched: times NEBO_QUERY_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_QUERY_RECEIPT_SIZE
before: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
