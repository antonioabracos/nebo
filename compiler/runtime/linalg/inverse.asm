; POSTFIXOS-MATRICIAIS-INVERSA-NORMAS-E-INNER-PRODUCTS-FECHAR-INVERSE-1-COM-SINGULARITY-CONDITIONING-RESULT-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F04 — exact checked 2x2 inverse as rational Result.
bits 64
default rel
%include "compiler/semantic/linalg/operator_protocols.inc"

section .text
global inverse2_i64_result

; rdi=matrix[a,b,c,d],rsi=result[status,det,d,-b,-c,a],rdx=min |det|.
inverse2_i64_result:
    test rdi, rdi
    jz .shape
    test rsi, rsi
    jz .shape
    mov r8, [rdi]
    imul r8, [rdi + 24]
    jo .overflow
    mov r9, [rdi + 8]
    imul r9, [rdi + 16]
    jo .overflow
    sub r8, r9
    jo .overflow
    test r8, r8
    jz .singular
    mov rax, r8
    test rax, rax
    jns .abs_ready
    neg rax
    jo .conditioning
.abs_ready:
    cmp rax, rdx
    jb .conditioning
    mov r9, [rdi + 8]
    neg r9
    jo .overflow
    mov r10, [rdi + 16]
    neg r10
    jo .overflow
    mov qword [rsi], LINALG_OK
    mov [rsi + 8], r8
    mov rax, [rdi + 24]
    mov [rsi + 16], rax
    mov [rsi + 24], r9
    mov [rsi + 32], r10
    mov rax, [rdi]
    mov [rsi + 40], rax
    xor eax, eax
    ret
.singular:
    mov qword [rsi], LINALG_ERR_SINGULAR
    mov qword [rsi + 8], 0
    mov rax, LINALG_ERR_SINGULAR
    ret
.conditioning:
    mov qword [rsi], LINALG_ERR_CONDITIONING
    mov [rsi + 8], r8
    mov rax, LINALG_ERR_CONDITIONING
    ret
.overflow:
    mov qword [rsi], LINALG_ERR_OVERFLOW
    mov rax, LINALG_ERR_OVERFLOW
    ret
.shape:
    mov rax, LINALG_ERR_SHAPE
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
