bits 64
default rel
%include "runtime/textual/format_language.inc"
section .rodata
positive: db 47,98,111,117,110,100,101,100,123,100,111,110,101,125
positive_len equ $ - positive
negative: db 47,119,104,105,108,101,123,120,125
negative_len equ $ - negative
loop_directive: db "/for{x}"
loop_directive_len equ $ - loop_directive
too_deep: db "/nest"
    times 17 db '{'
    db "x"
    times 17 db '}'
too_deep_len equ $ - too_deep
section .text
extern neboc_format_feature_available
extern neboc_format_feature_validate
global _start
_start:
    mov edi, 6509
    call neboc_format_feature_available
    cmp eax, 1
    jne .fail
    mov edi, 6509
    mov rsi, positive
    mov edx, positive_len
    call neboc_format_feature_validate
    test eax, eax
    jnz .fail
    mov edi, 6509
    mov rsi, negative
    mov edx, negative_len
    call neboc_format_feature_validate
    test eax, eax
    jz .fail
    mov edi, 6509
    mov rsi, loop_directive
    mov edx, loop_directive_len
    call neboc_format_feature_validate
    cmp eax, FORMAT_E_EFFECT
    jne .fail
    mov edi, 6509
    mov rsi, too_deep
    mov edx, too_deep_len
    call neboc_format_feature_validate
    cmp eax, FORMAT_E_LIMIT
    jne .fail
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
