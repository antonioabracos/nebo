; LEXER-PARSER-CST-E-AST-DA-DOCUMENTACAO-SEMANTICA-DOC-F01: Keyword `doc`, lexical boundary e rejection de `docs`
; Bounded native semantic-documentation kernel.
; rdi=input bytes, rsi=length, rdx=caller-owned 24-byte result.
; Success publishes digest, length, and stable operation tag atomically.
; Failure publishes nothing. No allocation, I/O, libc, network, or effects.
bits 64
default rel

global neboc_doc_keyword

%define DOC_MAX_INPUT 4096
%define DOC_TAG 1
%define hover_FNV_OFFSET 0xcbf29ce484222325
%define hover_FNV_PRIME  0x100000001b3

section .text
align 16
neboc_doc_keyword:
    test rdi, rdi
    jz .argument
    test rdx, rdx
    jz .argument
    test rdx, 7
    jnz .argument
    test rsi, rsi
    jz .length
    cmp rsi, DOC_MAX_INPUT
    ja .length
    lea rax, [rdi + rsi]
    cmp rax, rdi
    jb .length

    cmp rsi, 3
    jne .keyword
    cmp word [rdi], 0x6f64
    jne .keyword
    cmp byte [rdi + 2], 0x63
    jne .keyword

    mov rax, hover_FNV_OFFSET
    mov r8, hover_FNV_PRIME
    xor ecx, ecx
.scan:
    cmp rcx, rsi
    jae .publish
    movzx r9d, byte [rdi + rcx]
    test r9b, r9b
    jz .encoding
    cmp r9b, 0x7f
    ja .encoding
    xor rax, r9
    imul rax, r8
    inc rcx
    jmp .scan
.publish:
    xor rax, DOC_TAG
    mov qword [rdx], rax
    mov qword [rdx + 8], rsi
    mov qword [rdx + 16], DOC_TAG
    xor eax, eax
    xor edx, edx
    ret
.argument:
    mov eax, 1
    mov edx, 1
    ret
.length:
    mov eax, 2
    mov edx, 2
    ret
.encoding:
    mov eax, 3
    mov edx, 3
    ret
.keyword:
    mov eax, 4
    mov edx, 4
    ret
