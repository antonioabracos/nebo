bits 64
default rel
%include "runtime/structured_views.inc"
extern nebo_hierarchy_view_build
global _start
section .text
_start:
    lea rdi, [rel checklist]
    lea rsi, [rel receipt]
    call nebo_hierarchy_view_build
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_HIERARCHY_RECEIPT_COUNT_OFFSET], 10
    jne fail
    cmp qword [rel receipt + NEBO_HIERARCHY_RECEIPT_CHECKED_BYTES_OFFSET], 2
    jne fail
    lea rdi, [rel too_deep]
    lea rsi, [rel untouched]
    call nebo_hierarchy_view_build
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
nodes: dq 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
checked: db 0x05, 0x01
checklist: dq NEBO_HIERARCHY_CHECKLIST, nodes, 10, 3, checked, 2
too_deep: dq NEBO_HIERARCHY_TREE, nodes, 10, 17, 0, 0
untouched: times NEBO_HIERARCHY_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_HIERARCHY_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
