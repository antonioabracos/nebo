bits 64
default rel
%include "runtime/textual/format_language.inc"
section .rodata
positive: db 115,101,99,117,114,101,34,116,101,109,112,108,97,116,101,34
positive_len equ $ - positive
negative: db 114,34,117,110,116,101,114,109,105,110,97,116,101,100
negative_len equ $ - negative
section .text
extern neboc_format_feature_available
extern neboc_format_feature_validate
global _start
_start:
    mov edi, 6308
    call neboc_format_feature_available
    cmp eax, 1
    jne .fail
    mov edi, 6308
    mov rsi, positive
    mov edx, positive_len
    call neboc_format_feature_validate
    test eax, eax
    jnz .fail
    mov edi, 6308
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
