bits 64
default rel
%include "runtime/textual/format_language.inc"
section .rodata
positive: db 37,123,110,97,109,101,58,115,125
positive_len equ $ - positive
negative: db 37,122
negative_len equ $ - negative
section .text
extern neboc_format_feature_available
extern neboc_format_feature_validate
global _start
_start:
    mov edi, 6006
    call neboc_format_feature_available
    cmp eax, 1
    jne .fail_available
    mov edi, 6006
    mov rsi, positive
    mov edx, positive_len
    call neboc_format_feature_validate
    test eax, eax
    jnz .fail_positive
    mov edi, 6006
    mov rsi, negative
    mov edx, negative_len
    call neboc_format_feature_validate
    test eax, eax
    jz .fail_negative
    mov edi, 9999
    call neboc_format_feature_available
    test eax, eax
    jnz .fail_future
    xor edi, edi
    mov eax, 60
    syscall
.fail_available:
    mov edi, 11
    jmp .exit
.fail_positive:
    mov edi, eax
    jmp .exit
.fail_negative:
    mov edi, 13
    jmp .exit
.fail_future:
    mov edi, 14
.exit:
    mov eax, 60
    syscall
