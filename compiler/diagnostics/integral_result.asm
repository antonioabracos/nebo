; INTEGRAIS-NUMERICOS-E-SIMBOLICOS-FECHAR-INTEGRALRESULT-T-VALUE-ERROR-ITERATIONS-STATUS-CONVERGENCE-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F07 — stable IntegralResult machine/display diagnostics.
bits 64
default rel

section .rodata
ok: db "ok"
domain: db "domain"
method: db "method"
budget: db "budget"
overflow: db "overflow"
not_converged: db "not_converged"
unsupported: db "unsupported"
unknown: db "unknown"

section .text
global integral_status_name

; rdi=status -> rax=ASCII pointer,rdx=length. No implicit Console I/O.
integral_status_name:
    test rdi, rdi
    jz .ok
    cmp rdi, -10
    je .domain
    cmp rdi, -11
    je .method
    cmp rdi, -12
    je .budget
    cmp rdi, -13
    je .overflow
    cmp rdi, -14
    je .not_converged
    cmp rdi, -15
    je .unsupported
    lea rax, [unknown]
    mov edx, 7
    ret
.ok:
    lea rax, [ok]
    mov edx, 2
    ret
.domain:
    lea rax, [domain]
    mov edx, 6
    ret
.method:
    lea rax, [method]
    mov edx, 6
    ret
.budget:
    lea rax, [budget]
    mov edx, 6
    ret
.overflow:
    lea rax, [overflow]
    mov edx, 8
    ret
.not_converged:
    lea rax, [not_converged]
    mov edx, 13
    ret
.unsupported:
    lea rax, [unsupported]
    mov edx, 11
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
