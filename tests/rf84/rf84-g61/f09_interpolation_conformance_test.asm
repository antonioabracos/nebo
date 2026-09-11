bits 64
default rel
%include "runtime/textual/format_language.inc"
section .rodata
positive: db 36,123,99,111,110,102,111,114,109,97,110,99,101,125
positive_len equ $ - positive
negative: db 36,123,118,97,108,117,101,33,125
negative_len equ $ - negative
section .text
extern neboc_format_feature_available
extern neboc_format_feature_validate
global _start
_start:
    mov edi, 6109
    call neboc_format_feature_available
    cmp eax, 1
    jne .fail
    mov edi, 6109
    mov rsi, positive
    mov edx, positive_len
    call neboc_format_feature_validate
    test eax, eax
    jnz .fail
    mov edi, 6109
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
