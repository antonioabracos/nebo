; POSTFIXOS-MATRICIAIS-INVERSA-NORMAS-E-INNER-PRODUCTS-FECHAR-ADJOINT-EM-COMPLEX-LINEAR-ALGEBRA-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F03 — checked conjugate transpose of complex-i64 matrices.
bits 64
default rel
%include "compiler/semantic/linalg/operator_protocols.inc"

section .text
global adjoint_complex_i64

; rdi=input pairs,rsi=rows,rdx=cols,rcx=out pairs,r8=cell capacity.
; Return cells or linalg error; out is failure-atomic.
adjoint_complex_i64:
    push r12
    mov r12, rdx
    test rdi, rdi
    jz .shape
    test rcx, rcx
    jz .shape
    cmp rdi, rcx
    je .shape
    mov rax, rsi
    mul r12
    test rdx, rdx
    jnz .overflow
    cmp rax, r8
    ja .capacity
    push rax
    xor r9d, r9d
    mov r10, 0x8000000000000000
.preflight:
    cmp r9, rax
    jae .write_start
    mov r11, r9
    shl r11, 1
    cmp [rdi + r11 * 8 + 8], r10
    je .preflight_fail
    inc r9
    jmp .preflight
.write_start:
    xor r9d, r9d
.row:
    cmp r9, rsi
    jae .done
    xor r10d, r10d
.col:
    cmp r10, r12
    jae .next_row
    mov rax, r9
    imul rax, r12
    add rax, r10
    shl rax, 1
    mov r11, [rdi + rax * 8]
    mov r8, [rdi + rax * 8 + 8]
    neg r8
    mov rax, r10
    imul rax, rsi
    add rax, r9
    shl rax, 1
    mov [rcx + rax * 8], r11
    mov [rcx + rax * 8 + 8], r8
    inc r10
    jmp .col
.next_row:
    inc r9
    jmp .row
.done:
    pop rax
    jmp .return
.preflight_fail:
    add rsp, 8
.overflow:
    mov rax, LINALG_ERR_OVERFLOW
    jmp .return
.capacity:
    mov rax, LINALG_ERR_CAPACITY
    jmp .return
.shape:
    mov rax, LINALG_ERR_SHAPE
.return:
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
