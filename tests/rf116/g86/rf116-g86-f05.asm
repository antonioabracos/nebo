bits 64
default rel
%include "runtime/console_options.inc"
extern nebo_console_options_commit
global _start
section .text
_start:
    lea rdi, [rel success_request]
    call nebo_console_options_commit
    test eax, eax
    jnz fail
    cmp qword [rel dest], 1
    jne fail
    cmp qword [rel dest + 16], 3
    jne fail
    cmp qword [rel receipt + NEBO_OPTIONS_RECEIPT_COUNT_OFFSET], 3
    jne fail
    lea rdi, [rel failure_request]
    call nebo_console_options_commit
    cmp eax, NEBO_OPTIONS_VALIDATION_FAILED
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
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
validator:
    cmp rdi, [rsi]
    je .bad
    xor eax, eax
    ret
.bad:
    mov eax, 1
    ret
section .rodata
values: dq 1, 2, 3
reject_none: dq 99
reject_two: dq 2
section .data
success_request: dq values, 3, dest, 3, validator, reject_none, receipt
failure_request: dq values, 3, untouched, 3, validator, reject_two, untouched_receipt
untouched: times 3 dq 0xaaaaaaaaaaaaaaaa
untouched_receipt: times 3 dq 0xaaaaaaaaaaaaaaaa
section .bss
dest: resq 3
receipt: resb NEBO_OPTIONS_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
