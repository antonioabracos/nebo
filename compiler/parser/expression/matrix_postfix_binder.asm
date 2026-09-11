; POSTFIXOS-MATRICIAIS-INVERSA-NORMAS-E-INNER-PRODUCTS-FECHAR-POSTFIX-GRAMMAR-E-SOURCE-MAPPING-DE-SUPERSCRIPTS-DELIMITERS-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F01 — native postfix planning metadata, not frontend syntax activation.
bits 64
default rel

%define MATRIX_OPERAND 1
%define POSTFIX_TRANSPOSE 1
%define POSTFIX_ADJOINT 2
%define POSTFIX_INVERSE 3
%define POSTFIX_PRECEDENCE 170

section .text
global matrix_postfix_plan

; rdi=token id,rsi=operand-kind,rdx=plan[operation,precedence] -> 0/-1/-4.
matrix_postfix_plan:
    test rdx, rdx
    jz .shape
    cmp rsi, MATRIX_OPERAND
    jne .type
    cmp rdi, POSTFIX_TRANSPOSE
    jb .shape
    cmp rdi, POSTFIX_INVERSE
    ja .shape
    mov [rdx], rdi
    mov qword [rdx + 8], POSTFIX_PRECEDENCE
    xor eax, eax
    ret
.shape:
    mov rax, -1
    ret
.type:
    mov rax, -4
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
