; POSTFIXOS-MATRICIAIS-INVERSA-NORMAS-E-INNER-PRODUCTS-FECHAR-OWNERSHIP-LAYOUT-ABI-KERNELS-E-NO-HIDDEN-ALLOCATION-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F06 — allocation-free dense-kernel descriptor validation.
bits 64
default rel
%include "compiler/semantic/linalg/operator_protocols.inc"

section .text
global linalg_validate_kernel_desc

; rdi=descriptor,rsi=required type,rdx=max cells,rcx=required power-of-two alignment.
; Return logical cell count or a negative typed error.
linalg_validate_kernel_desc:
    test rdi, rdi
    jz .shape
    cmp [rdi + LINALG_TYPE_TAG], rsi
    jne .type
    mov r8, [rdi + LINALG_COLS]
    cmp [rdi + LINALG_STRIDE], r8
    jb .shape
    mov r10, rdx
    mov rax, [rdi + LINALG_ROWS]
    mul r8
    test rdx, rdx
    jnz .overflow
    cmp rax, r10
    ja .capacity
    test rax, rax
    jz .valid
    mov r8, [rdi + LINALG_DATA]
    test r8, r8
    jz .shape
    test rcx, rcx
    jz .valid
    mov r9, rcx
    dec r9
    test rcx, r9
    jnz .shape
    test r8, r9
    jnz .shape
.valid:
    ret
.shape:
    mov rax, LINALG_ERR_SHAPE
    ret
.type:
    mov rax, LINALG_ERR_TYPE
    ret
.capacity:
    mov rax, LINALG_ERR_CAPACITY
    ret
.overflow:
    mov rax, LINALG_ERR_OVERFLOW
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
