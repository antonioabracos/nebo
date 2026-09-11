bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_dashboard_compose
global _start
section .text
_start:
    lea rdi, [rel dashboard]
    lea rsi, [rel receipt]
    call nebo_layout_dashboard_compose
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_DASHBOARD_RECEIPT_COUNT_OFFSET], 2
    jne fail
    cmp qword [rel receipt + NEBO_DASHBOARD_RECEIPT_ROOT_ID_OFFSET], 1
    jne fail
    lea rdi, [rel duplicate_dashboard]
    lea rsi, [rel untouched]
    call nebo_layout_dashboard_compose
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
nodes:
    dq NEBO_LAYOUT_GRID, 1, 0, 0, 80, 24, 0, NEBO_LAYOUT_NODE_READY
    dq NEBO_LAYOUT_ROW, 2, 0, 0, 80, 12, 0, NEBO_LAYOUT_NODE_READY
duplicate_nodes:
    dq NEBO_LAYOUT_GRID, 1, 0, 0, 80, 24, 0, NEBO_LAYOUT_NODE_READY
    dq NEBO_LAYOUT_ROW, 1, 0, 0, 80, 12, 0, NEBO_LAYOUT_NODE_READY
profile: dq 1, NEBO_LAYOUT_GRID, NEBO_PROFILE_VIEW_DASHBOARD, 40, 12, 160, 48, NEBO_LAYOUT_TARGET_HEADLESS, 0, NEBO_PROFILE_READY
dashboard: dq nodes, 2, 1, profile
duplicate_dashboard: dq duplicate_nodes, 2, 1, profile
untouched: times NEBO_DASHBOARD_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_DASHBOARD_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
