; INTEGRAIS-NUMERICOS-E-SIMBOLICOS-FECHAR-INTEGRAL-DE-CONTORNO-E-ORIENTACAO-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F04 — oriented sampled 2D contour line integral.
bits 64
default rel

%define INTEGRAL_ERR_DOMAIN -10
%define INTEGRAL_ERR_OVERFLOW -13

section .text
global contour_integral2_i64

; rdi=field vectors [Fx,Fy],rsi=segment deltas [dx,dy],rdx=count,
; rcx=orientation (+1|-1),r8=result[status,value,evaluations,orientation].
contour_integral2_i64:
    push r12
    test r8, r8
    jz .domain_return
    mov qword [r8], 0
    mov qword [r8 + 8], 0
    mov qword [r8 + 16], 0
    mov qword [r8 + 24], 0
    test rdi, rdi
    jz .domain
    test rsi, rsi
    jz .domain
    test rdx, rdx
    jz .domain
    cmp rcx, 1
    je .start
    cmp rcx, -1
    jne .domain
.start:
    xor r9d, r9d
    xor r10d, r10d
.loop:
    mov r11, r9
    shl r11, 1
    mov rax, [rdi + r11 * 8]
    imul rax, [rsi + r11 * 8]
    jo .overflow
    mov r12, [rdi + r11 * 8 + 8]
    imul r12, [rsi + r11 * 8 + 8]
    jo .overflow
    add rax, r12
    jo .overflow
    add r10, rax
    jo .overflow
    inc r9
    cmp r9, rdx
    jb .loop
    imul r10, rcx
    jo .overflow
    mov qword [r8], 0
    mov [r8 + 8], r10
    mov [r8 + 16], rdx
    mov [r8 + 24], rcx
    xor eax, eax
    jmp .return
.overflow:
    mov qword [r8], INTEGRAL_ERR_OVERFLOW
    mov rax, INTEGRAL_ERR_OVERFLOW
    jmp .return
.domain:
    mov qword [r8], INTEGRAL_ERR_DOMAIN
.domain_return:
    mov rax, INTEGRAL_ERR_DOMAIN
.return:
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
