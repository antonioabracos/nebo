bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_labels
global _start
section .text
_start:
    lea rdi, [rel labels]
    lea rsi, [rel result]
    call nebo_geometry_labels
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_LABEL_ANCHOR_OFFSET], 5
    jne fail
    cmp qword [rel result + NEBO_LABEL_STATE_OFFSET], NEBO_LABEL_READY
    jne fail
    lea rdi, [rel bad_pointer]
    lea rsi, [rel untouched]
    call nebo_geometry_labels
    cmp eax, NEBO_GEOMETRY_INVALID
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
title: db "CPU"
suffix: db "%"
label: db "usage"
section .data
labels: dq title, 3, suffix, 1, label, 5, 5, 0, 0
bad_pointer: dq 0, 1, suffix, 1, label, 5, 5, 0, 0
untouched: times NEBO_LABEL_SIZE db 0xaa
section .bss
result: resb NEBO_LABEL_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
