bits 64
default rel
%include "runtime/structured_views.inc"
extern nebo_structured_conformance_scan
global _start
section .text
_start:
    lea rdi, [rel scan]
    lea rsi, [rel first]
    call nebo_structured_conformance_scan
    test eax, eax
    jnz fail
    lea rdi, [rel scan]
    lea rsi, [rel second]
    call nebo_structured_conformance_scan
    test eax, eax
    jnz fail
    mov rax, [rel first + NEBO_CONFORMANCE_RECEIPT_DIGEST_OFFSET]
    cmp rax, [rel second + NEBO_CONFORMANCE_RECEIPT_DIGEST_OFFSET]
    jne fail
    cmp qword [rel first + NEBO_CONFORMANCE_RECEIPT_COUNT_OFFSET], 8
    jne fail
    lea rdi, [rel bad_scan]
    lea rsi, [rel untouched]
    call nebo_structured_conformance_scan
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
references:
    dq 1, 1, 24, 0x11, 2, 1, 3, 0x22, 3, 1, 7, 0x33, 4, 1, 10, 0x44
    dq 5, 1, 2, 0x55, 6, 1, 8, 0x66, 7, 1, 32, 0x77, 8, 1, 20, 0x88
bad_references: dq 2, 1, 1, 0x11, 1, 1, 1, 0x22
scan: dq references, 8
bad_scan: dq bad_references, 2
untouched: times NEBO_CONFORMANCE_RECEIPT_SIZE db 0xaa
section .bss
first: resb NEBO_CONFORMANCE_RECEIPT_SIZE
second: resb NEBO_CONFORMANCE_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
