; PRODUTOS-LINEARES-COMPOSICAO-E-RELACOES-GEOMETRICAS-FECHAR-FUNCTION-OPERATOR-COMPOSITION-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F06 — typed unary-i64 function composition descriptor.
bits 64
default rel
%include "compiler/semantic/linalg/operator_protocols.inc"

section .text
global compose_plan_i64
global compose_apply_i64

; Function descriptor: +0 fn pointer,+8 input type,+16 output type.
; rdi=outer,rsi=inner,rdx=composite[32] -> status; output failure-atomic.
compose_plan_i64:
    test rdi, rdi
    jz .shape
    test rsi, rsi
    jz .shape
    test rdx, rdx
    jz .shape
    mov rax, [rsi + 16]
    cmp rax, [rdi + 8]
    jne .type
    mov rcx, [rsi]
    test rcx, rcx
    jz .shape
    mov r8, [rdi]
    test r8, r8
    jz .shape
    mov [rdx], rcx
    mov [rdx + 8], r8
    mov rcx, [rsi + 8]
    mov [rdx + 16], rcx
    mov rcx, [rdi + 16]
    mov [rdx + 24], rcx
    mov eax, LINALG_OK
    ret
.shape:
    mov rax, LINALG_ERR_SHAPE
    ret
.type:
    mov rax, LINALG_ERR_TYPE
    ret

; rdi=composite,rsi=value -> rax=outer(inner(value)).
compose_apply_i64:
    push r12
    mov r12, [rdi + 8]
    mov rax, [rdi]
    mov rdi, rsi
    call rax
    mov rdi, rax
    call r12
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
