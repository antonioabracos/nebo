bits 64
default rel
%include "runtime/style_tokens.inc"
%include "runtime/color_target.inc"
%include "runtime/color_roles.inc"
extern nebo_style_plan_validate
global _start
section .text
_start:
    lea rdi, [rel plan]
    lea rsi, [rel receipt]
    call nebo_style_plan_validate
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_STYLE_RECEIPT_ACCESSIBLE_OFFSET], 1
    jne fail
    cmp qword [rel receipt + NEBO_STYLE_RECEIPT_STATE_OFFSET], NEBO_STYLE_PLAN_READY
    jne fail
    lea rax, [rel inaccessible]
    mov [rel plan + NEBO_STYLE_PLAN_A11Y_OFFSET], rax
    lea rdi, [rel plan]
    lea rsi, [rel untouched]
    call nebo_style_plan_validate
    cmp eax, NEBO_STYLE_ACCESSIBILITY
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
status_text: db "ok"
name_text: db "status"
section .data
core: dq NEBO_STYLE_BOLD, 0, NEBO_STYLE_FRAGMENT_READY
optional: dq NEBO_STYLE_DIM, NEBO_STYLE_BLINK, NEBO_STYLE_FRAGMENT_READY
status: dq NEBO_STATUS_SUCCESS, status_text, 2, '+', NEBO_ROLE_ACCENT, NEBO_STATUS_READY
colors: dq 0xffffffff, 0x000000ff, 0x00ff00ff, 7, NEBO_COLOR_TARGET_ANSI, 0, NEBO_STYLE_COLORS_READY
font: dq 1, 16, NEBO_COLOR_TARGET_ANSI, 0, 0, 0, NEBO_FONT_FALLBACK_TARGET_DEFAULT, NEBO_FONT_READY
fallback: dq NEBO_PROFILE_NO_COLOR, 0, 1, 0, NEBO_PROFILE_NO_COLOR, 0, 0, 0, NEBO_FALLBACK_READY
a11y: dq 3, name_text, 6, 0, 0, 0, 0, NEBO_A11Y_READY
inaccessible: times 8 dq 0
plan: dq core, optional, status, colors, font, fallback, a11y, NEBO_COLOR_TARGET_ANSI
untouched: times NEBO_STYLE_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_STYLE_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
