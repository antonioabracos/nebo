; INTEGRAIS-NUMERICOS-E-SIMBOLICOS-FECHAR-INTEGRACAO-SIMBOLICA-E-CONSTANT-OF-INTEGRATION-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F06 — bounded symbolic monomial integration rule.
bits 64
default rel

%define INTEGRAL_ERR_DOMAIN -10
%define INTEGRAL_ERR_OVERFLOW -13
%define INTEGRAL_UNSUPPORTED -15

section .text
global symbolic_integrate_monomial_i64

; rdi=coefficient,rsi=nonnegative exponent,rdx=max admitted exponent,
; rcx=out[status,numerator,denominator,new exponent,integration-constant tag].
symbolic_integrate_monomial_i64:
    test rcx, rcx
    jz .domain_return
    test rsi, rsi
    js .domain
    cmp rsi, rdx
    ja .unsupported
    mov r8, rsi
    inc r8
    jo .overflow
    mov qword [rcx], 0
    mov [rcx + 8], rdi
    mov [rcx + 16], r8
    mov [rcx + 24], r8
    mov qword [rcx + 32], 1
    xor eax, eax
    ret
.unsupported:
    mov qword [rcx], INTEGRAL_UNSUPPORTED
    mov rax, INTEGRAL_UNSUPPORTED
    ret
.overflow:
    mov qword [rcx], INTEGRAL_ERR_OVERFLOW
    mov rax, INTEGRAL_ERR_OVERFLOW
    ret
.domain:
    mov qword [rcx], INTEGRAL_ERR_DOMAIN
.domain_return:
    mov rax, INTEGRAL_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
