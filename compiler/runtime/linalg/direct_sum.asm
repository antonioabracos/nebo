; PRODUTOS-LINEARES-COMPOSICAO-E-RELACOES-GEOMETRICAS-FECHAR-DIRECT-SUM-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F05 — bounded dense-matrix direct sum.
bits 64
default rel
%include "compiler/semantic/linalg/operator_protocols.inc"

section .text
global direct_sum_i64

; rdi=A desc,rsi=B desc,rdx=out desc,rcx=out storage,r8=cell capacity.
direct_sum_i64:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r12, r12
    jz .shape
    test r13, r13
    jz .shape
    test r14, r14
    jz .shape
    test r15, r15
    jz .shape
    mov rax, [r12 + LINALG_TYPE_TAG]
    cmp rax, [r13 + LINALG_TYPE_TAG]
    jne .type
    mov r9, [r12 + LINALG_ROWS]
    add r9, [r13 + LINALG_ROWS]
    jc .overflow
    mov r10, [r12 + LINALG_COLS]
    add r10, [r13 + LINALG_COLS]
    jc .overflow
    mov rax, r9
    mul r10
    test rdx, rdx
    jnz .overflow
    cmp rax, r8
    ja .capacity
    push rax
    xor ecx, ecx
.zero:
    cmp rcx, rax
    jae .copy_a_start
    mov qword [r15 + rcx * 8], 0
    inc rcx
    jmp .zero
.copy_a_start:
    xor r8d, r8d
.a_row:
    cmp r8, [r12 + LINALG_ROWS]
    jae .copy_b_start
    xor ecx, ecx
.a_col:
    cmp rcx, [r12 + LINALG_COLS]
    jae .a_next
    mov rax, r8
    imul rax, [r12 + LINALG_STRIDE]
    add rax, rcx
    mov rdx, [r12 + LINALG_DATA]
    mov rbx, [rdx + rax * 8]
    mov rax, r8
    imul rax, r10
    add rax, rcx
    mov [r15 + rax * 8], rbx
    inc rcx
    jmp .a_col
.a_next:
    inc r8
    jmp .a_row
.copy_b_start:
    xor r8d, r8d
.b_row:
    cmp r8, [r13 + LINALG_ROWS]
    jae .descriptor
    xor ecx, ecx
.b_col:
    cmp rcx, [r13 + LINALG_COLS]
    jae .b_next
    mov rax, r8
    imul rax, [r13 + LINALG_STRIDE]
    add rax, rcx
    mov rdx, [r13 + LINALG_DATA]
    mov rbx, [rdx + rax * 8]
    mov rax, r8
    add rax, [r12 + LINALG_ROWS]
    imul rax, r10
    add rax, rcx
    add rax, [r12 + LINALG_COLS]
    mov [r15 + rax * 8], rbx
    inc rcx
    jmp .b_col
.b_next:
    inc r8
    jmp .b_row
.descriptor:
    mov [r14 + LINALG_DATA], r15
    mov [r14 + LINALG_ROWS], r9
    mov [r14 + LINALG_COLS], r10
    mov [r14 + LINALG_STRIDE], r10
    mov rax, [r12 + LINALG_TYPE_TAG]
    mov [r14 + LINALG_TYPE_TAG], rax
    pop rax
    jmp .return
.shape:
    mov rax, LINALG_ERR_SHAPE
    jmp .return
.type:
    mov rax, LINALG_ERR_TYPE
    jmp .return
.capacity:
    mov rax, LINALG_ERR_CAPACITY
    jmp .return
.overflow:
    mov rax, LINALG_ERR_OVERFLOW
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
