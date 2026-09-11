bits 64
default rel
%include "runtime/textual/format_language.inc"
section .rodata
positive: db 101,118,97,108,117,97,116,105,111,110,45,111,114,100,101,114
positive_len equ $ - positive
negative: db 98,97,100,32,105,110,112,117,116,33
negative_len equ $ - negative
section .text
extern neboc_format_feature_available
extern neboc_format_feature_validate
global _start
_start:
    mov edi, 5904
    call neboc_format_feature_available
    cmp eax, 1
    jne .fail
    mov edi, 5904
    mov rsi, positive
    mov edx, positive_len
    call neboc_format_feature_validate
    test eax, eax
    jnz .fail
    mov edi, 5904
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
