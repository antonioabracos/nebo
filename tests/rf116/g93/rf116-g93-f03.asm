bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_profile_validate
global _start
section .text
_start:
    lea rdi, [rel profile]
    lea rsi, [rel result]
    call nebo_layout_profile_validate
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_PROFILE_VIEW_KIND_OFFSET], NEBO_PROFILE_VIEW_DASHBOARD
    jne fail
    lea rdi, [rel inverted]
    lea rsi, [rel untouched]
    call nebo_layout_profile_validate
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
profile: dq 1, NEBO_LAYOUT_GRID, NEBO_PROFILE_VIEW_DASHBOARD, 40, 12, 160, 48, NEBO_LAYOUT_TARGET_HEADLESS, 0, 0
inverted: dq 2, NEBO_LAYOUT_ROW, NEBO_PROFILE_VIEW_COMPACT, 80, 24, 40, 12, NEBO_LAYOUT_TARGET_HEADLESS, 0, 0
untouched: times NEBO_PROFILE_SIZE db 0xaa
section .bss
result: resb NEBO_PROFILE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
