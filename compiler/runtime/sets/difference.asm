; OPERADORES-DE-CONJUNTOS-E-RELACOES-FECHAR-DIFFERENCE-E-SYMMETRIC-DIFFERENCE-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F03 — exact difference and symmetric difference.
bits 64
default rel

section .text
global set_difference_i64
global set_symmetric_difference_i64

; rdi=A,rsi=|A|,rdx=B,rcx=|B|,r8=out,r9=capacity -> count or -1.
set_difference_i64:
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    xor r10d, r10d
    xor r11d, r11d
    xor eax, eax
.d_count:
    cmp r10, r13
    je .d_capacity
    cmp r11, r15
    je .d_tail
    mov rdx, [r12 + r10 * 8]
    cmp rdx, [r14 + r11 * 8]
    je .d_equal
    jl .d_keep
    inc r11
    jmp .d_count
.d_equal:
    inc r10
    inc r11
    jmp .d_count
.d_keep:
    inc r10
    inc rax
    jmp .d_count
.d_tail:
    mov rdx, r13
    sub rdx, r10
    add rax, rdx
.d_capacity:
    cmp rax, r9
    ja .d_fail
    push rax
    xor r10d, r10d
    xor r11d, r11d
    xor ecx, ecx
.d_write:
    cmp r10, r13
    je .d_done
    cmp r11, r15
    je .d_copy
    mov rdx, [r12 + r10 * 8]
    cmp rdx, [r14 + r11 * 8]
    je .d_skip_both
    jl .d_store
    inc r11
    jmp .d_write
.d_skip_both:
    inc r10
    inc r11
    jmp .d_write
.d_copy:
    mov rdx, [r12 + r10 * 8]
.d_store:
    mov [r8 + rcx * 8], rdx
    inc rcx
    inc r10
    jmp .d_write
.d_done:
    pop rax
    jmp .d_return
.d_fail:
    mov rax, -1
.d_return:
    pop r15
    pop r14
    pop r13
    pop r12
    ret

set_symmetric_difference_i64:
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    xor r10d, r10d
    xor r11d, r11d
    xor eax, eax
.s_count:
    cmp r10, r13
    je .s_tail_b
    cmp r11, r15
    je .s_tail_a
    mov rdx, [r12 + r10 * 8]
    cmp rdx, [r14 + r11 * 8]
    je .s_equal
    jl .s_a
    inc r11
    inc rax
    jmp .s_count
.s_a:
    inc r10
    inc rax
    jmp .s_count
.s_equal:
    inc r10
    inc r11
    jmp .s_count
.s_tail_a:
    mov rdx, r13
    sub rdx, r10
    add rax, rdx
    jmp .s_capacity
.s_tail_b:
    mov rdx, r15
    sub rdx, r11
    add rax, rdx
.s_capacity:
    cmp rax, r9
    ja .s_fail
    push rax
    xor r10d, r10d
    xor r11d, r11d
    xor ecx, ecx
.s_write:
    cmp r10, r13
    je .s_copy_b
    cmp r11, r15
    je .s_copy_a
    mov rdx, [r12 + r10 * 8]
    cmp rdx, [r14 + r11 * 8]
    je .s_skip
    jl .s_store_a
    mov rdx, [r14 + r11 * 8]
    inc r11
    jmp .s_store
.s_store_a:
    inc r10
    jmp .s_store
.s_skip:
    inc r10
    inc r11
    jmp .s_write
.s_copy_a:
    cmp r10, r13
    je .s_done
    mov rdx, [r12 + r10 * 8]
    inc r10
    jmp .s_store
.s_copy_b:
    cmp r11, r15
    je .s_done
    mov rdx, [r14 + r11 * 8]
    inc r11
.s_store:
    mov [r8 + rcx * 8], rdx
    inc rcx
    jmp .s_write
.s_done:
    pop rax
    jmp .s_return
.s_fail:
    mov rax, -1
.s_return:
    pop r15
    pop r14
    pop r13
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
