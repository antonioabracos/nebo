bits 64
default rel
%include "runtime/structured_views.inc"
extern nebo_record_view_build
global _start
section .text
_start:
    lea rdi, [rel object]
    lea rsi, [rel receipt]
    call nebo_record_view_build
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_RECORD_RECEIPT_FIELD_COUNT_OFFSET], 2
    jne fail
    cmp qword [rel receipt + NEBO_RECORD_RECEIPT_SCHEMA_VERSION_OFFSET], 4
    jne fail
    lea rdi, [rel no_schema]
    lea rsi, [rel untouched]
    call nebo_record_view_build
    cmp eax, NEBO_VIEW_SCHEMA
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
fields: dq 1, 10, 0, 2, 11, 1
object: dq NEBO_RECORD_OBJECT, fields, 2, 44, 4
no_schema: dq NEBO_RECORD_OBJECT, fields, 2, 0, 4
untouched: times NEBO_RECORD_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_RECORD_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
