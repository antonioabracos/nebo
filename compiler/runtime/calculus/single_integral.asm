; INTEGRAIS-NUMERICOS-E-SIMBOLICOS-FECHAR-INTEGRAL-SIMPLES-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F02 — exact rational composite trapezoid over sampled i64 values.
bits 64
default rel

%define INTEGRAL_ERR_DOMAIN -10
%define INTEGRAL_ERR_OVERFLOW -13

section .text
global integrate_samples_trapezoid_i64

; rdi=samples,rsi=count>=2,rdx=step numerator,rcx=positive step denominator,
; r8=result[status,numerator,denominator,evaluations].
integrate_samples_trapezoid_i64:
    test rdi, rdi
    jz .domain
    test r8, r8
    jz .domain
    cmp rsi, 2
    jb .domain
    test rcx, rcx
    jle .domain
    mov r9, [rdi]
    add r9, [rdi + rsi * 8 - 8]
    jo .overflow
    mov r10d, 1
.interior:
    mov rax, rsi
    dec rax
    cmp r10, rax
    jae .scale
    mov rax, [rdi + r10 * 8]
    add rax, rax
    jo .overflow
    add r9, rax
    jo .overflow
    inc r10
    jmp .interior
.scale:
    imul r9, rdx
    jo .overflow
    mov r10, rcx
    add r10, r10
    jo .overflow
    mov qword [r8], 0
    mov [r8 + 8], r9
    mov [r8 + 16], r10
    mov [r8 + 24], rsi
    xor eax, eax
    ret
.overflow:
    mov qword [r8], INTEGRAL_ERR_OVERFLOW
    mov rax, INTEGRAL_ERR_OVERFLOW
    ret
.domain:
    test r8, r8
    jz .domain_return
    mov qword [r8], INTEGRAL_ERR_DOMAIN
.domain_return:
    mov rax, INTEGRAL_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
