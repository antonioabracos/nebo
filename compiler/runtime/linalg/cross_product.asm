; PRODUTOS-LINEARES-COMPOSICAO-E-RELACOES-GEOMETRICAS-FECHAR-CROSS-PRODUCT-EM-VECTOR3-GEOMETRY-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F03 — checked Vector3 cross product.
bits 64
default rel
%include "compiler/semantic/linalg/operator_protocols.inc"

section .text
global cross3_i64_checked

; rdi=left[3],rsi=right[3],rdx=out[3] -> status; out is failure-atomic.
cross3_i64_checked:
    test rdi, rdi
    jz .shape
    test rsi, rsi
    jz .shape
    test rdx, rdx
    jz .shape
    sub rsp, 24

    mov rax, [rdi + 8]
    imul rax, [rsi + 16]
    jo .overflow
    mov r8, [rdi + 16]
    imul r8, [rsi + 8]
    jo .overflow
    sub rax, r8
    jo .overflow
    mov [rsp], rax

    mov rax, [rdi + 16]
    imul rax, [rsi]
    jo .overflow
    mov r8, [rdi]
    imul r8, [rsi + 16]
    jo .overflow
    sub rax, r8
    jo .overflow
    mov [rsp + 8], rax

    mov rax, [rdi]
    imul rax, [rsi + 8]
    jo .overflow
    mov r8, [rdi + 8]
    imul r8, [rsi]
    jo .overflow
    sub rax, r8
    jo .overflow
    mov [rsp + 16], rax

    mov rax, [rsp]
    mov [rdx], rax
    mov rax, [rsp + 8]
    mov [rdx + 8], rax
    mov rax, [rsp + 16]
    mov [rdx + 16], rax
    add rsp, 24
    mov eax, LINALG_OK
    ret
.overflow:
    add rsp, 24
    mov rax, LINALG_ERR_OVERFLOW
    ret
.shape:
    mov rax, LINALG_ERR_SHAPE
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
