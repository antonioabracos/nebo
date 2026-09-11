bits 64
default rel
%include "compiler/lexer/format_literals.inc"
section .text
global neboc_format_lex_classify
; rdi=bytes, rsi=len; rax=syntax class. Exact source is never dispatched.
neboc_format_lex_classify:
    test rdi, rdi
    jz .none
    cmp rsi, 3
    jb .none
    xor ecx, ecx
.scan:
    cmp rcx, rsi
    jae .none
    mov al, [rdi + rcx]
    cmp al, '$'
    jne .canonical
    ; Only an odd run of immediately preceding backslashes escapes `${`.
    ; This keeps `\\${value}` as an interpolation after the decoded slash.
    mov rdx, rcx
    xor r8d, r8d
.backslash_run:
    test rdx, rdx
    jz .backslash_parity
    cmp byte [rdi + rdx - 1], 92
    jne .backslash_parity
    inc r8
    dec rdx
    jmp .backslash_run
.backslash_parity:
    test r8b, 1
    jnz .next
.dollar_unescaped:
    lea rdx, [rcx + 1]
    cmp rdx, rsi
    jae .canonical
    cmp byte [rdi + rdx], '{'
    je .b
.canonical:
    cmp al, '.'
    jne .next
    lea rdx, [rcx + 8]
    cmp rdx, rsi
    ja .next
    cmp dword [rdi + rcx + 1], 'form'
    jne .console
    cmp dword [rdi + rcx + 5], 'at('
    je .a
.console:
    lea rdx, [rcx + 9]
    cmp rdx, rsi
    ja .next
    cmp dword [rdi + rcx + 1], 'cons'
    jne .next
    cmp dword [rdi + rcx + 5], 'ole('
    je .c
.next:
    inc rcx
    jmp .scan
.a:
    mov eax, FORMAT_SYNTAX_A
    ret
.b:
    mov eax, FORMAT_SYNTAX_B
    ret
.c:
    mov eax, FORMAT_SYNTAX_C_REJECTED
    ret
.none:
    xor eax, eax
    ret
