; PRODUTOS-LINEARES-COMPOSICAO-E-RELACOES-GEOMETRICAS-FECHAR-HADAMARD-E-TENSOR-KRONECKER-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F04 — checked Hadamard and tensor products.
bits 64
default rel
%include "compiler/semantic/linalg/operator_protocols.inc"

section .text
global hadamard_i64_checked
global tensor_i64_checked

; rdi=A,rsi=B,rdx=count,rcx=out -> status; two-pass failure atomicity.
hadamard_i64_checked:
    xor r8d, r8d
.h_check:
    cmp r8, rdx
    jae .h_write_start
    mov rax, [rdi + r8 * 8]
    imul rax, [rsi + r8 * 8]
    jo .h_overflow
    inc r8
    jmp .h_check
.h_write_start:
    xor r8d, r8d
.h_write:
    cmp r8, rdx
    jae .h_ok
    mov rax, [rdi + r8 * 8]
    imul rax, [rsi + r8 * 8]
    mov [rcx + r8 * 8], rax
    inc r8
    jmp .h_write
.h_overflow:
    mov rax, LINALG_ERR_OVERFLOW
    ret
.h_ok:
    mov eax, LINALG_OK
    ret

; rdi=A,rsi=|A|,rdx=B,rcx=|B|,r8=out,r9=capacity -> count or error.
tensor_i64_checked:
    push r12
    push r13
    mov r12, rdx
    mov r13, rcx
    mov rax, rsi
    mul r13
    test rdx, rdx
    jnz .t_overflow
    cmp rax, r9
    ja .t_capacity
    push rax
    xor r10d, r10d
.t_check_outer:
    cmp r10, rsi
    jae .t_write_start
    xor r11d, r11d
.t_check_inner:
    cmp r11, r13
    jae .t_check_next
    mov rax, [rdi + r10 * 8]
    imul rax, [r12 + r11 * 8]
    jo .t_preflight_fail
    inc r11
    jmp .t_check_inner
.t_check_next:
    inc r10
    jmp .t_check_outer
.t_write_start:
    xor r10d, r10d
    xor edx, edx
.t_outer:
    cmp r10, rsi
    jae .t_done
    xor r11d, r11d
.t_inner:
    cmp r11, r13
    jae .t_next
    mov rax, [rdi + r10 * 8]
    imul rax, [r12 + r11 * 8]
    mov [r8 + rdx * 8], rax
    inc rdx
    inc r11
    jmp .t_inner
.t_next:
    inc r10
    jmp .t_outer
.t_done:
    pop rax
    pop r13
    pop r12
    ret
.t_preflight_fail:
    add rsp, 8
.t_overflow:
    mov rax, LINALG_ERR_OVERFLOW
    jmp .t_return
.t_capacity:
    mov rax, LINALG_ERR_CAPACITY
.t_return:
    pop r13
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
