bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_lifecycle_apply
global _start
section .text
_start:
    lea rdi, [rel present]
    lea rsi, [rel receipt]
    call nebo_layout_lifecycle_apply
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_LIFECYCLE_RECEIPT_GENERATION_OFFSET], 1
    jne fail
    cmp qword [rel receipt + NEBO_LIFECYCLE_RECEIPT_EVALUATIONS_OFFSET], 1
    jne fail
    lea rdi, [rel stale_refresh]
    lea rsi, [rel untouched]
    call nebo_layout_lifecycle_apply
    cmp eax, NEBO_LAYOUT_LIFECYCLE
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
present: dq NEBO_LIFECYCLE_PRESENT, NEBO_LIFECYCLE_PLAN_READY, 0, 0, NEBO_LIFECYCLE_EFFECT_PRESENT, 0
stale_refresh: dq NEBO_LIFECYCLE_REFRESH, NEBO_LIFECYCLE_PLAN_READY, 4, 4, NEBO_LIFECYCLE_EFFECT_PRESENT, NEBO_LIFECYCLE_CAP_REFRESH
untouched: times NEBO_LIFECYCLE_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_LIFECYCLE_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
