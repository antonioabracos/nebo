bits 64
default rel
%include "runtime/p02_integration.inc"
extern nebo_p02_render_plan_close
global _start
section .text
_start:
    lea rdi, [rel request]
    lea rsi, [rel receipt]
    call nebo_p02_render_plan_close
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_P02_RECEIPT_COMPONENTS_OFFSET], 5
    jne fail
    cmp qword [rel receipt + NEBO_P02_RECEIPT_TARGET_OFFSET], NEBO_P02_TARGET_HEADLESS
    jne fail
    cmp qword [rel receipt + NEBO_P02_RECEIPT_STATE_OFFSET], NEBO_P02_READY
    jne fail
    lea rdi, [rel bad_request]
    lea rsi, [rel untouched]
    call nebo_p02_render_plan_close
    cmp eax, NEBO_P02_CONFLICT
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
registry: dq 2, 0x11, 1
document: dq 3, 0x22, NEBO_P02_TARGET_HEADLESS, 1
style: dq 0x33, NEBO_P02_TARGET_HEADLESS, 1, 1
layout: dq 3, 2, 0x44, 1
view: dq 8, 0x55, 1
bad_view: dq 8, 0x55, 0
request: dq registry, document, style, layout, view, 9, NEBO_P02_REQUIRED_FLAGS
bad_request: dq registry, document, style, layout, bad_view, 9, NEBO_P02_REQUIRED_FLAGS
untouched: times NEBO_P02_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_P02_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
