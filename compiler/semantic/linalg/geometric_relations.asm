; PRODUTOS-LINEARES-COMPOSICAO-E-RELACOES-GEOMETRICAS-FECHAR-ORTHOGONALITY-PARALLEL-E-OVERLOAD-DISAMBIGUATION-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F07 — exact checked orthogonal/parallel relations.
bits 64
default rel

extern dot_i64_checked
extern cross3_i64_checked
section .text
global vectors_orthogonal_i64
global vectors_parallel3_i64

; rdi=A,rsi=B,rdx=count,rcx=boolean out -> linalg status.
vectors_orthogonal_i64:
    test rcx, rcx
    jz .shape
    push rcx
    sub rsp, 16
    mov rcx, rsp
    call dot_i64_checked
    test rax, rax
    jnz .orth_return
    cmp qword [rsp], 0
    sete dl
    mov rcx, [rsp + 16]
    mov [rcx], dl
.orth_return:
    add rsp, 24
    ret
.shape:
    mov rax, -1
    ret

; rdi=A[3],rsi=B[3],rdx=boolean out -> linalg status.
vectors_parallel3_i64:
    test rdx, rdx
    jz .parallel_shape
    push rdx
    sub rsp, 32
    mov rdx, rsp
    call cross3_i64_checked
    test rax, rax
    jnz .parallel_return
    mov rcx, [rsp]
    or rcx, [rsp + 8]
    or rcx, [rsp + 16]
    sete dl
    mov rcx, [rsp + 32]
    mov [rcx], dl
.parallel_return:
    add rsp, 40
    ret
.parallel_shape:
    mov rax, -1
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
