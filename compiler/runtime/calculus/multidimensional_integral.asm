; INTEGRAIS-NUMERICOS-E-SIMBOLICOS-FECHAR-INTEGRAIS-DUPLA-E-TRIPLA-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F03 — exact rectangular-cell double/triple grid integration.
bits 64
default rel

%define INTEGRAL_ERR_DOMAIN -10
%define INTEGRAL_ERR_OVERFLOW -13

section .text
global integrate_grid_i64

; rdi=cell samples,rsi=count,rdx=cell-volume numerator,rcx=positive denominator,
; r8=dimension (2|3),r9=result[status,numerator,denominator,evaluations,dimension].
integrate_grid_i64:
    test rdi, rdi
    jz .domain
    test r9, r9
    jz .domain
    test rsi, rsi
    jz .domain
    test rcx, rcx
    jle .domain
    cmp r8, 2
    je .sum_start
    cmp r8, 3
    jne .domain
.sum_start:
    xor eax, eax
    xor r10d, r10d
.sum:
    add rax, [rdi + r10 * 8]
    jo .overflow
    inc r10
    cmp r10, rsi
    jb .sum
    imul rax, rdx
    jo .overflow
    mov qword [r9], 0
    mov [r9 + 8], rax
    mov [r9 + 16], rcx
    mov [r9 + 24], rsi
    mov [r9 + 32], r8
    xor eax, eax
    ret
.overflow:
    mov qword [r9], INTEGRAL_ERR_OVERFLOW
    mov rax, INTEGRAL_ERR_OVERFLOW
    ret
.domain:
    test r9, r9
    jz .domain_return
    mov qword [r9], INTEGRAL_ERR_DOMAIN
.domain_return:
    mov rax, INTEGRAL_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
