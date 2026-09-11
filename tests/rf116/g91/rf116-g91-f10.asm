bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_document_validate
global _start
section .text
_start:
    lea rdi, [rel document]
    lea rsi, [rel receipt]
    call nebo_geometry_document_validate
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_DOCUMENT_RECEIPT_COUNT_OFFSET], 3
    jne fail
    cmp qword [rel receipt + NEBO_DOCUMENT_RECEIPT_STATE_OFFSET], NEBO_DOCUMENT_READY
    jne fail
    lea rdi, [rel unsupported_live]
    lea rsi, [rel untouched]
    call nebo_geometry_document_validate
    cmp eax, NEBO_GEOMETRY_TARGET
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
section .rodata
label_text: db "cpu"
section .data
surface: dq NEBO_SURFACE_HEADLESS_WINDOW, 1, 0, 0, 80, 24, 0, 0, NEBO_SURFACE_READY
panel: dq 1, 2, 0, 0, 1, NEBO_PANEL_READY
label: dq 0, 0, 0, 0, label_text, 3, 5, 0, NEBO_LABEL_READY
document: dq surface, 1, panel, 1, label, 1, NEBO_TARGET_HEADLESS, 0
unsupported_live: dq surface, 1, panel, 1, label, 1, NEBO_TARGET_LIVE, 0
untouched: times NEBO_DOCUMENT_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_DOCUMENT_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
