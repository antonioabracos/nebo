bits 64
default rel
%include "runtime/textual/format_language.inc"
section .rodata
positive: db 109,34,108,105,110,101,32,111,110,101,92,110,108,105,110,101,32,116,119,111,34
positive_len equ $ - positive
negative: db 114,34,117,110,116,101,114,109,105,110,97,116,101,100
negative_len equ $ - negative
section .text
extern neboc_format_feature_available
extern neboc_format_feature_validate
global _start
_start:
    mov edi, 6302
    call neboc_format_feature_available
    cmp eax, 1
    jne .fail
    mov edi, 6302
    mov rsi, positive
    mov edx, positive_len
    call neboc_format_feature_validate
    test eax, eax
    jnz .fail
    mov edi, 6302
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
