bits 64
default rel
%include "compiler/parser/format_contract.inc"
section .text
global neboc_format_parse_balanced
; rdi=bytes, rsi=len. Bounds (), {}, [] with a frozen depth of 16.
neboc_format_parse_balanced:
    test rdi, rdi
    jz .bad
    xor ecx, ecx
    xor r8d, r8d
.scan:
    cmp rcx, rsi
    je .done
    mov al, [rdi + rcx]
    cmp al, '('
    je .open
    cmp al, '{'
    je .open
    cmp al, '['
    je .open
    cmp al, ')'
    je .close
    cmp al, '}'
    je .close
    cmp al, ']'
    jne .next
.close:
    dec r8d
    js .bad
    jmp .next
.open:
    inc r8d
    cmp r8d, 16
    ja .bad
.next:
    inc rcx
    jmp .scan
.done:
    test r8d, r8d
    jnz .bad
    xor eax, eax
    ret
.bad:
    mov eax, FORMAT_PARSE_E_SYNTAX
    ret
