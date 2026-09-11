bits 64
default rel
%include "runtime/structured_views.inc"
extern nebo_value_marker_build
global _start
section .text
_start:
    lea rdi, [rel truncated]
    lea rsi, [rel receipt]
    call nebo_value_marker_build
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_VALUE_RECEIPT_TRUNCATED_OFFSET], 1
    jne fail
    cmp qword [rel receipt + NEBO_VALUE_RECEIPT_VISIBLE_OFFSET], 32
    jne fail
    lea rdi, [rel bad_missing]
    lea rsi, [rel untouched]
    call nebo_value_marker_build
    cmp eax, NEBO_VIEW_CONFLICT
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
truncated_label: db 'truncated'
missing_label: db 'missing'
truncated: dq NEBO_VALUE_PRESENT, 100, 32, truncated_label, 9
bad_missing: dq NEBO_VALUE_MISSING, 1, 0, missing_label, 7
untouched: times NEBO_VALUE_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_VALUE_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
