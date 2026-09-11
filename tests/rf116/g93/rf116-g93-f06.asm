bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_responsive_resolve
global _start
section .text
_start:
    lea rdi, [rel wrapped]
    lea rsi, [rel result]
    call nebo_layout_responsive_resolve
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_RESPONSIVE_RESULT_WIDTH_OFFSET], 40
    jne fail
    cmp qword [rel result + NEBO_RESPONSIVE_RESULT_HEIGHT_OFFSET], 8
    jne fail
    cmp qword [rel result + NEBO_RESPONSIVE_LINES_OFFSET], 2
    jne fail
    lea rdi, [rel no_wrap]
    lea rsi, [rel untouched]
    call nebo_layout_responsive_resolve
    cmp eax, NEBO_LAYOUT_LIMIT
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
wrapped: dq 40, 20, 80, 4, 10, 4, NEBO_WRAP_WORD, 0, 0, 0, 0
no_wrap: dq 40, 20, 80, 4, 10, 4, NEBO_WRAP_NONE, 0, 0, 0, 0
untouched: times NEBO_RESPONSIVE_SIZE db 0xaa
section .bss
result: resb NEBO_RESPONSIVE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
