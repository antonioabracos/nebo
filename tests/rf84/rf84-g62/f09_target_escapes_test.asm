bits 64
default rel
%include "runtime/textual/format_language.inc"
section .rodata
positive: db 101,115,99,97,112,101,40,106,115,111,110,41
positive_len equ $ - positive
negative: db 57,112,114,111,102,105,108,101
negative_len equ $ - negative
section .text
extern neboc_format_feature_available
extern neboc_format_feature_validate
global _start
_start:
    mov edi, 6209
    call neboc_format_feature_available
    cmp eax, 1
    jne .fail
    mov edi, 6209
    mov rsi, positive
    mov edx, positive_len
    call neboc_format_feature_validate
    test eax, eax
    jnz .fail
    mov edi, 6209
    mov rsi, negative
    mov edx, negative_len
    call neboc_format_feature_validate
    test eax, eax
    jz .fail
    mov edi, 9999
    call neboc_format_feature_available
    test eax, eax
    jnz .fail
    xor edi, edi
    mov eax, 60
    syscall
.fail:
    mov edi, 1
    mov eax, 60
    syscall
