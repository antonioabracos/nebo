bits 64
default rel
%include "runtime/console_call.inc"
extern nebo_console_call_finalize
global _start
section .text
_start:
    lea rdi, [rel request]
    lea rsi, [rel receipt]
    call nebo_console_call_finalize
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_CONSOLE_RECEIPT_EFFECTS_OFFSET], NEBO_CONSOLE_EFFECT_WRITE
    jne fail
    mov qword [rel request + NEBO_CONSOLE_CALL_CAPABILITIES_OFFSET], 0
    lea rdi, [rel request]
    lea rsi, [rel untouched]
    call nebo_console_call_finalize
    cmp eax, NEBO_CONSOLE_CALL_EFFECT_DENIED
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
request:
    dq 1, NEBO_CONSOLE_EFFECT_WRITE, NEBO_CONSOLE_EFFECT_WRITE
    dq NEBO_CONSOLE_RETURN_RECEIPT, render_plan, 0
render_plan: dq 0x52454e444552
section .bss
receipt: resb NEBO_CONSOLE_RECEIPT_SIZE
section .data
untouched: times NEBO_CONSOLE_RECEIPT_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
