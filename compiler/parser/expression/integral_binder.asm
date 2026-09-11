; INTEGRAIS-NUMERICOS-E-SIMBOLICOS-FECHAR-BINDER-GRAMMAR-PARA-INTEGRAIS-E-VARIABLE-DOMAIN-BINDING-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F01 — failure-atomic native plan used by the live source binder vertical.
bits 64
default rel

%define INTEGRAL_OK 0
%define INTEGRAL_ERR_DOMAIN -10
%define INTEGRAL_ERR_METHOD -11
%define INTEGRAL_ERR_BUDGET -12

section .text
global integral_plan

; rdi=variable tag,rsi=domain[lower,upper],rdx=config[method,tolerance,budget],
; rcx=out[variable,lower,upper,method,tolerance,budget,orientation].
integral_plan:
    test rcx, rcx
    jz .domain
    mov qword [rcx], 0
    mov qword [rcx + 8], 0
    mov qword [rcx + 16], 0
    mov qword [rcx + 24], 0
    mov qword [rcx + 32], 0
    mov qword [rcx + 40], 0
    mov qword [rcx + 48], 0
    test rdi, rdi
    jz .domain
    test rsi, rsi
    jz .domain
    test rdx, rdx
    jz .domain
    mov r8, [rsi]
    mov r9, [rsi + 8]
    cmp r8, r9
    jg .domain
    mov r10, [rdx]
    cmp r10, 1
    jb .method
    cmp r10, 3
    ja .method
    mov r11, [rdx + 8]
    test r11, r11
    jle .budget
    mov rax, [rdx + 16]
    test rax, rax
    jle .budget
    mov [rcx], rdi
    mov [rcx + 8], r8
    mov [rcx + 16], r9
    mov [rcx + 24], r10
    mov [rcx + 32], r11
    mov [rcx + 40], rax
    mov qword [rcx + 48], 1
    mov eax, INTEGRAL_OK
    ret
.domain:
    mov rax, INTEGRAL_ERR_DOMAIN
    ret
.method:
    mov rax, INTEGRAL_ERR_METHOD
    ret
.budget:
    mov rax, INTEGRAL_ERR_BUDGET
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
