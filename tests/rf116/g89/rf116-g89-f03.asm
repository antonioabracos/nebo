bits 64
default rel
%include "runtime/console_options.inc"
extern nebo_console_options_normalize
global _start
section .text
_start:
    lea rdi, [rel request]
    call nebo_console_options_normalize
    test eax, eax
    jnz fail
    cmp qword [rel output + NEBO_OPTION_VALUE_KIND_OFFSET], 1
    jne fail
    cmp qword [rel output + NEBO_OPTION_VALUE_SIZE + NEBO_OPTION_VALUE_KIND_OFFSET], 3
    jne fail
    lea rax, [rel conflicts]
    mov [rel request + NEBO_OPTIONS_NORMALIZE_VALUES_OFFSET], rax
    lea rax, [rel untouched]
    mov [rel request + NEBO_OPTIONS_NORMALIZE_DESTINATION_OFFSET], rax
    lea rdi, [rel request]
    call nebo_console_options_normalize
    cmp eax, NEBO_OPTIONS_CONFLICT
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
values:
    dq 3, 30, 0
    dq 1, 10, 0
conflicts:
    dq 1, 10, 2
    dq 2, 20, 1
align 8
request: dq values, 2, output, 2, receipt
section .bss
output: resb NEBO_OPTION_VALUE_SIZE * 2
receipt: resb NEBO_OPTIONS_RECEIPT_SIZE
section .data
untouched: times NEBO_OPTION_VALUE_SIZE * 2 db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
