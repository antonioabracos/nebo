; COMENTARIOS-DE-BLOCO-TRIVIA-FORMATTER-ROUND-TRIP-FOLDING-E-SOURCE-MAPS-F02: Lexer nested block comments com depth budget
; Canonical nested block-comment scanner, depth budget 64.
; rdi=complete bytes, rsi=length, rdx=caller-owned 24-byte result.
; Publishes consumed bytes, maximum depth and stable tag only after a complete
; outer close. Unterminated, trailing-code and depth-overflow inputs publish zero.
bits 64
default rel
global neboc_block_comment_lexer
section .text
align 16
neboc_block_comment_lexer:
    test rdi, rdi
    jz .argument
    test rdx, rdx
    jz .argument
    test rdx, 7
    jnz .argument
    cmp rsi, 4
    jb .length
    cmp rsi, 4096
    ja .length
    lea rax, [rdi + rsi]
    cmp rax, rdi
    jb .length
    cmp word [rdi], 0x2a2f
    jne .syntax
    mov ecx, 2
    mov r8d, 1
    mov r9d, 1
.scan:
    cmp rcx, rsi
    jae .unterminated
    lea r10, [rcx + 1]
    cmp r10, rsi
    jae .unterminated
    cmp byte [rdi + rcx], '/'
    jne .maybe_close
    cmp byte [rdi + rcx + 1], '*'
    jne .advance
    inc r8d
    cmp r8d, 64
    ja .depth
    cmp r8d, r9d
    cmova r9d, r8d
    add ecx, 2
    jmp .scan
.maybe_close:
    cmp byte [rdi + rcx], '*'
    jne .advance
    cmp byte [rdi + rcx + 1], '/'
    jne .advance
    dec r8d
    add ecx, 2
    test r8d, r8d
    jnz .scan
    cmp rcx, rsi
    jne .syntax
    mov qword [rdx], r9
    mov qword [rdx + 8], rsi
    mov qword [rdx + 16], 34
    xor eax, eax
    xor edx, edx
    ret
.advance:
    inc ecx
    jmp .scan
.argument:
    mov eax, 1
    mov edx, 1
    ret
.length:
    mov eax, 2
    mov edx, 2
    ret
.syntax:
    mov eax, 4
    mov edx, 4
    ret
.unterminated:
    mov eax, 5
    mov edx, 5
    ret
.depth:
    mov eax, 6
    mov edx, 6
    ret
