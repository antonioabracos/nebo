bits 64
default rel
%include "runtime/structured_views.inc"
extern nebo_table_configure
global _start
section .text
_start:
    lea rdi, [rel config]
    lea rsi, [rel receipt]
    call nebo_table_configure
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_TABLE_CONFIG_RECEIPT_PAGE_COUNT_OFFSET], 3
    jne fail
    cmp qword [rel receipt + NEBO_TABLE_CONFIG_RECEIPT_FREEZE_HEADER_OFFSET], 1
    jne fail
    lea rdi, [rel oversized_page]
    lea rsi, [rel untouched]
    call nebo_table_configure
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
columns: dq 1, 3, 7
config: dq columns, 3, 8, 18, 1
oversized_page: dq columns, 3, 33, 18, 1
untouched: times NEBO_TABLE_CONFIG_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_TABLE_CONFIG_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
