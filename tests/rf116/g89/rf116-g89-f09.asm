bits 64
default rel
%include "runtime/color_target.inc"
%include "runtime/console_options.inc"
%include "runtime/console_call.inc"
%include "runtime/render_intent.inc"
%include "runtime/p01_integration.inc"
extern nebo_p01_prepare_console_call
global _start
section .text
_start:
    lea rdi, [rel request]
    call nebo_p01_prepare_console_call
    test eax, eax
    jnz fail
    cmp qword [rel scratch + NEBO_OPTION_VALUE_KIND_OFFSET], 1
    jne fail
    cmp qword [rel plan + NEBO_RENDER_PLAN_STATE_OFFSET], NEBO_RENDER_PLAN_READY
    jne fail
    cmp qword [rel receipt + NEBO_CONSOLE_RECEIPT_STATE_OFFSET], NEBO_CONSOLE_RECEIPT_READY
    jne fail
    lea rax, [rel plan]
    cmp qword [rel receipt + NEBO_CONSOLE_RECEIPT_RENDER_PLAN_OFFSET], rax
    jne fail
    lea rax, [rel conflicts]
    mov [rel request + NEBO_P01_REQUEST_VALUES_OFFSET], rax
    lea rax, [rel untouched_plan]
    mov [rel request + NEBO_P01_REQUEST_PLAN_OFFSET], rax
    lea rax, [rel untouched_receipt]
    mov [rel request + NEBO_P01_REQUEST_RECEIPT_OFFSET], rax
    lea rdi, [rel request]
    call nebo_p01_prepare_console_call
    cmp eax, NEBO_OPTIONS_CONFLICT
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched_plan], rax
    jne fail
    cmp qword [rel untouched_receipt], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .data
values:
    dq 3, 0x101820ff, 0
    dq 1, 0xffffffff, 0
conflicts:
    dq 1, 0xffffffff, 2
    dq 2, 0x101820ff, 1
align 8
request:
    dq values, 2, scratch, 2
    dq NEBO_COLOR_TARGET_ANSI, NEBO_CONSOLE_EFFECT_WRITE
    dq NEBO_CONSOLE_EFFECT_WRITE, 1
    dq NEBO_CONSOLE_RETURN_RECEIPT, 0, plan, receipt
section .bss
scratch: resb NEBO_OPTION_VALUE_SIZE * 2
plan: resb NEBO_RENDER_PLAN_SIZE
receipt: resb NEBO_CONSOLE_RECEIPT_SIZE
section .data
untouched_plan: times NEBO_RENDER_PLAN_SIZE db 0xaa
untouched_receipt: times NEBO_CONSOLE_RECEIPT_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
