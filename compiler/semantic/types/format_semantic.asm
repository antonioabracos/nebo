bits 64
default rel
%include "compiler/semantic/types/format_semantic.inc"
section .text
global neboc_format_require_pure
; rdi=expression bytes, rsi=len. A conservative pure-expression boundary.
neboc_format_require_pure:
    test rdi, rdi
    jz .effect
    xor ecx, ecx
.scan:
    cmp rcx, rsi
    je .ok
    mov al, [rdi + rcx]
    cmp al, '!'
    je .effect
    cmp al, '='
    je .effect
    cmp al, ';'
    je .effect
    inc rcx
    jmp .scan
.ok:
    xor eax, eax
    ret
.effect:
    mov eax, FORMAT_SEMANTIC_E_EFFECT
    ret
