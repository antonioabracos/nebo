; POSTFIXOS-MATRICIAIS-INVERSA-NORMAS-E-INNER-PRODUCTS-FECHAR-TRANSPOSE-T-E-VIEW-VALUE-POLICIES-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F02 — bounded dense transpose into caller-owned storage.
bits 64
default rel
%include "compiler/semantic/linalg/operator_protocols.inc"

section .text
global transpose_i64

; rdi=input desc,rsi=out desc,rdx=out storage,rcx=capacity -> cells or error.
transpose_i64:
    push r12
    push r13
    push r14
    mov r13, rdi
    mov r14, rsi
    mov r12, rdx
    test r13, r13
    jz .shape
    test r14, r14
    jz .shape
    test r12, r12
    jz .shape
    cmp r12, [r13 + LINALG_DATA]
    je .shape
    mov r8, [r13 + LINALG_ROWS]
    mov r9, [r13 + LINALG_COLS]
    mov rax, r8
    mul r9
    test rdx, rdx
    jnz .overflow
    cmp rax, rcx
    ja .capacity
    push rax
    xor r10d, r10d
.row:
    cmp r10, r8
    jae .descriptor
    xor r11d, r11d
.col:
    cmp r11, r9
    jae .next_row
    mov rax, r10
    imul rax, [r13 + LINALG_STRIDE]
    add rax, r11
    mov rdx, [r13 + LINALG_DATA]
    mov rcx, [rdx + rax * 8]
    mov rax, r11
    imul rax, r8
    add rax, r10
    mov [r12 + rax * 8], rcx
    inc r11
    jmp .col
.next_row:
    inc r10
    jmp .row
.descriptor:
    mov [r14 + LINALG_DATA], r12
    mov [r14 + LINALG_ROWS], r9
    mov [r14 + LINALG_COLS], r8
    mov [r14 + LINALG_STRIDE], r8
    mov rax, [r13 + LINALG_TYPE_TAG]
    mov [r14 + LINALG_TYPE_TAG], rax
    pop rax
    jmp .return
.shape:
    mov rax, LINALG_ERR_SHAPE
    jmp .return
.capacity:
    mov rax, LINALG_ERR_CAPACITY
    jmp .return
.overflow:
    mov rax, LINALG_ERR_OVERFLOW
.return:
    pop r14
    pop r13
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
