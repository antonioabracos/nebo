; PRODUTOS-LINEARES-COMPOSICAO-E-RELACOES-GEOMETRICAS-FECHAR-DOT-INNER-SCALAR-PRODUCT-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F02 — checked signed-i64 dot product.
bits 64
default rel
%include "compiler/semantic/linalg/operator_protocols.inc"

section .text
global dot_i64_checked

; rdi=left,rsi=right,rdx=count,rcx=result -> status; result is failure-atomic.
dot_i64_checked:
    test rcx, rcx
    jz .shape
    xor eax, eax
    xor r8d, r8d
.loop:
    cmp r8, rdx
    jae .store
    mov r9, [rdi + r8 * 8]
    imul r9, [rsi + r8 * 8]
    jo .overflow
    add rax, r9
    jo .overflow
    inc r8
    jmp .loop
.store:
    mov [rcx], rax
    mov eax, LINALG_OK
    ret
.shape:
    mov rax, LINALG_ERR_SHAPE
    ret
.overflow:
    mov rax, LINALG_ERR_OVERFLOW
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
