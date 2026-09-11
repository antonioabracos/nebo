bits 64
default rel
%include "runtime/structured_views.inc"
extern nebo_inspection_plan
global _start
section .text
_start:
    lea rdi, [rel preview]
    lea rsi, [rel receipt]
    call nebo_inspection_plan
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_INSPECT_RECEIPT_MAX_ITEMS_OFFSET], 8
    jne fail
    cmp qword [rel receipt + NEBO_INSPECT_RECEIPT_SAFE_FLAGS_OFFSET], NEBO_INSPECT_FLAG_PUBLIC_METADATA
    jne fail
    lea rdi, [rel sensitive]
    lea rsi, [rel untouched]
    call nebo_inspection_plan
    cmp eax, NEBO_VIEW_PRIVACY
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
metadata: db 'shape:row'
preview: dq NEBO_INSPECT_PREVIEW, 7, metadata, 9, NEBO_INSPECT_FLAG_PUBLIC_METADATA, 8
sensitive: dq NEBO_INSPECT_FULL, 7, metadata, 9, NEBO_INSPECT_FLAG_SENSITIVE, 8
untouched: times NEBO_INSPECT_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_INSPECT_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
