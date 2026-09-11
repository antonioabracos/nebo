bits 64
default rel
%include "runtime/structured_views.inc"
extern nebo_virtual_window_plan
global _start
section .text
_start:
    lea rdi, [rel window]
    lea rsi, [rel receipt]
    call nebo_virtual_window_plan
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_WINDOW_RECEIPT_START_OFFSET], 45
    jne fail
    cmp qword [rel receipt + NEBO_WINDOW_RECEIPT_END_OFFSET], 65
    jne fail
    cmp qword [rel receipt + NEBO_WINDOW_RECEIPT_MATERIALIZED_OFFSET], 20
    jne fail
    lea rdi, [rel too_large]
    lea rsi, [rel untouched]
    call nebo_virtual_window_plan
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
source: dq 1, 2, 3
window: dq source, 100, 50, 10, 5, 8
too_large: dq source, 100, 50, 33, 0, 8
untouched: times NEBO_WINDOW_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_WINDOW_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
