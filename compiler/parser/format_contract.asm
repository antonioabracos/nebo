bits 64
default rel
%include "compiler/parser/format_contract.inc"
section .text
global neboc_format_parse_balanced
; rdi=bytes, rsi=len. Bounds and type-matches (), {}, [] with a frozen depth
; of 16 while treating quoted/escaped bytes as literal content.
neboc_format_parse_balanced:
    test rdi, rdi
    jz .bad
    sub rsp, 24
    xor ecx, ecx
    xor r8d, r8d
    xor r9d, r9d                ; in quote
    xor r10d, r10d              ; escaped
.scan:
    cmp rcx, rsi
    je .done
    mov al, [rdi + rcx]
    test r9d, r9d
    jz .outside
    test r10d, r10d
    jnz .escaped
    cmp al, 92
    je .escape
    cmp al, '"'
    je .quote_close
    jmp .next
.escape:
    mov r10d, 1
    jmp .next
.escaped:
    xor r10d, r10d
    jmp .next
.quote_close:
    xor r9d, r9d
    jmp .next
.outside:
    cmp al, '"'
    jne .bracket
    mov r9d, 1
    jmp .next
.bracket:
    cmp al, '('
    je .open_round
    cmp al, '{'
    je .open_curly
    cmp al, '['
    je .open_square
    cmp al, ')'
    je .close_round
    cmp al, '}'
    je .close_curly
    cmp al, ']'
    jne .next
.close_square:
    mov dl, '['
    jmp .close
.close_curly:
    mov dl, '{'
    jmp .close
.close_round:
    mov dl, '('
.close:
    test r8d, r8d
    jz .bad_stack
    dec r8d
    cmp byte [rsp + r8], dl
    jne .bad_stack
    jmp .next
.open_round:
    mov dl, '('
    jmp .open
.open_curly:
    mov dl, '{'
    jmp .open
.open_square:
    mov dl, '['
.open:
    cmp r8d, 16
    jae .bad_stack
    mov [rsp + r8], dl
    inc r8d
.next:
    inc rcx
    jmp .scan
.done:
    test r8d, r8d
    jnz .bad_stack
    test r9d, r9d
    jnz .bad_stack
    test r10d, r10d
    jnz .bad_stack
    xor eax, eax
    add rsp, 24
    ret
.bad_stack:
    add rsp, 24
.bad:
    mov eax, FORMAT_PARSE_E_SYNTAX
    ret
