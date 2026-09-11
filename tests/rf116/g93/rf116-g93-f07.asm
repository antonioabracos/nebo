bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_composite_build
global _start
section .text
_start:
    lea rdi, [rel tabs]
    lea rsi, [rel result]
    call nebo_layout_composite_build
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_COMPOSITE_KIND_OFFSET], NEBO_LAYOUT_TABS
    jne fail
    cmp qword [rel result + NEBO_COMPOSITE_ACTIVE_OFFSET], 1
    jne fail
    cmp qword [rel result + NEBO_COMPOSITE_STATE_OFFSET], NEBO_COMPOSITE_READY
    jne fail
    lea rdi, [rel bad_split]
    lea rsi, [rel untouched]
    call nebo_layout_composite_build
    cmp eax, NEBO_LAYOUT_CONFLICT
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
children: dq 10, 11, 12
tabs: dq NEBO_LAYOUT_TABS, 7, children, 3, 1, 0, 0, 0
bad_split: dq NEBO_LAYOUT_SPLIT, 8, children, 3, 0, 50, NEBO_COMPOSITE_AXIS_HORIZONTAL, 0
untouched: times NEBO_COMPOSITE_SIZE db 0xaa
section .bss
result: resb NEBO_COMPOSITE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
