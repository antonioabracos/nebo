bits 64
default rel
%include "runtime/console_options.inc"
%include "runtime/console_call.inc"
%include "runtime/color_target.inc"
%include "runtime/render_intent.inc"
extern nebo_render_intent_build
global _start
section .text
_start:
    lea rdi, [rel intent]
    lea rsi, [rel plan]
    call nebo_render_intent_build
    test eax, eax
    jnz fail
    cmp qword [rel plan + NEBO_RENDER_PLAN_STATE_OFFSET], NEBO_RENDER_PLAN_READY
    jne fail
    cmp qword [rel plan + NEBO_RENDER_PLAN_COUNT_OFFSET], 2
    jne fail
    lea rax, [rel unordered]
    mov [rel intent + NEBO_RENDER_INTENT_OPTIONS_OFFSET], rax
    lea rdi, [rel intent]
    lea rsi, [rel untouched]
    call nebo_render_intent_build
    cmp eax, NEBO_RENDER_INTENT_ORDER
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
options:
    dq 1, 0x1122, 0
    dq 3, 0x3344, 0
unordered:
    dq 3, 0x3344, 0
    dq 1, 0x1122, 0
section .data
intent:
    dq options, 2, NEBO_COLOR_TARGET_ANSI
    dq NEBO_CONSOLE_EFFECT_WRITE, NEBO_CONSOLE_EFFECT_WRITE
section .bss
plan: resb NEBO_RENDER_PLAN_SIZE
section .data
untouched: times NEBO_RENDER_PLAN_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
