bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_box_validate
global _start
section .text
_start:
    lea rdi, [rel box]
    lea rsi, [rel result]
    call nebo_layout_box_validate
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_BOX_TOTAL_WIDTH_OFFSET], 84
    jne fail
    cmp qword [rel result + NEBO_BOX_TOTAL_HEIGHT_OFFSET], 24
    jne fail
    lea rdi, [rel negative]
    lea rsi, [rel untouched]
    call nebo_layout_box_validate
    cmp eax, NEBO_LAYOUT_INVALID
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
box: dq 80, 20, 1, 1, 1, 1, 1, 1, 1, 1, NEBO_BOX_ALIGN_CENTER, NEBO_BOX_ALIGN_START, 0, 0, 0
negative: dq 80, 20, -1, 1, 1, 1, 1, 1, 1, 1, NEBO_BOX_ALIGN_CENTER, NEBO_BOX_ALIGN_START, 0, 0, 0
untouched: times NEBO_BOX_SIZE db 0xaa
section .bss
result: resb NEBO_BOX_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
