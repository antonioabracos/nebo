; INTEGRAIS-NUMERICOS-E-SIMBOLICOS-FECHAR-METODOS-NUMERICOS-TOLERANCIA-ADAPTATIVIDADE-E-BUDGETS-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F05 — bounded adaptive estimate selection with explicit tolerance.
bits 64
default rel

%define INTEGRAL_ERR_DOMAIN -10
%define INTEGRAL_ERR_BUDGET -12
%define INTEGRAL_ERR_OVERFLOW -13
%define INTEGRAL_NOT_CONVERGED -14

section .text
global integral_adaptive_decide_i64

; rdi=coarse estimate,rsi=fine estimate,rdx=nonnegative tolerance,
; rcx=evaluations,r8=budget,r9=result[status,value,error,evaluations,converged].
integral_adaptive_decide_i64:
    test r9, r9
    jz .domain_return
    test rdx, rdx
    js .domain
    test rcx, rcx
    jz .domain
    cmp rcx, r8
    ja .budget
    mov rax, rsi
    sub rax, rdi
    jo .overflow
    test rax, rax
    jns .error_ready
    neg rax
    jo .overflow
.error_ready:
    mov [r9 + 8], rsi
    mov [r9 + 16], rax
    mov [r9 + 24], rcx
    cmp rax, rdx
    ja .not_converged
    mov qword [r9], 0
    mov qword [r9 + 32], 1
    xor eax, eax
    ret
.not_converged:
    mov qword [r9], INTEGRAL_NOT_CONVERGED
    mov qword [r9 + 32], 0
    mov rax, INTEGRAL_NOT_CONVERGED
    ret
.budget:
    mov qword [r9], INTEGRAL_ERR_BUDGET
    mov rax, INTEGRAL_ERR_BUDGET
    ret
.overflow:
    mov qword [r9], INTEGRAL_ERR_OVERFLOW
    mov rax, INTEGRAL_ERR_OVERFLOW
    ret
.domain:
    mov qword [r9], INTEGRAL_ERR_DOMAIN
.domain_return:
    mov rax, INTEGRAL_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
