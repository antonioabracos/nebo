; OPERADORES-DE-CONJUNTOS-E-RELACOES-FECHAR-UNION-E-INTERSECTION-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F02 — deterministic union/intersection, caller-owned output.
bits 64
default rel

section .text
global set_union_i64
global set_intersection_i64

; Common ABI: rdi=A, rsi=|A|, rdx=B, rcx=|B|, r8=out, r9=capacity.
; Return element count, or -1 without touching out when capacity is insufficient.
set_union_i64:
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
.u_count:
    cmp r10, r13
    je .u_tail_b
    cmp r11, r15
    je .u_tail_a
    mov rdx, [r12 + r10 * 8]
    cmp rdx, [r14 + r11 * 8]
    je .u_both
    jl .u_a
    inc r11
    inc rax
    jmp .u_count
.u_a:
    inc r10
    inc rax
    jmp .u_count
.u_both:
    inc r10
    inc r11
    inc rax
    jmp .u_count
.u_tail_a:
    mov rdx, r13
    sub rdx, r10
    add rax, rdx
    jmp .u_capacity
.u_tail_b:
    mov rdx, r15
    sub rdx, r11
    add rax, rdx
.u_capacity:
    cmp rax, r9
    ja .capacity
    push rax
    xor r10d, r10d
    xor r11d, r11d
    xor ecx, ecx
.u_write:
    cmp r10, r13
    je .u_copy_b
    cmp r11, r15
    je .u_copy_a
    mov rdx, [r12 + r10 * 8]
    cmp rdx, [r14 + r11 * 8]
    je .u_write_both
    jl .u_write_a
    mov rdx, [r14 + r11 * 8]
    inc r11
    jmp .u_store
.u_write_a:
    inc r10
    jmp .u_store
.u_write_both:
    inc r10
    inc r11
.u_store:
    mov [r8 + rcx * 8], rdx
    inc rcx
    jmp .u_write
.u_copy_a:
    cmp r10, r13
    je .u_done
    mov rdx, [r12 + r10 * 8]
    inc r10
    jmp .u_store
.u_copy_b:
    cmp r11, r15
    je .u_done
    mov rdx, [r14 + r11 * 8]
    inc r11
    jmp .u_store
.u_done:
    pop rax
    jmp .return
.capacity:
    mov rax, -1
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    ret

set_intersection_i64:
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
.i_count:
    cmp r10, r13
    je .i_capacity
    cmp r11, r15
    je .i_capacity
    mov rdx, [r12 + r10 * 8]
    cmp rdx, [r14 + r11 * 8]
    je .i_both
    jl .i_next_a
    inc r11
    jmp .i_count
.i_next_a:
    inc r10
    jmp .i_count
.i_both:
    inc r10
    inc r11
    inc rax
    jmp .i_count
.i_capacity:
    cmp rax, r9
    ja .i_fail
    push rax
    xor r10d, r10d
    xor r11d, r11d
    xor ecx, ecx
.i_write:
    cmp r10, r13
    je .i_done
    cmp r11, r15
    je .i_done
    mov rdx, [r12 + r10 * 8]
    cmp rdx, [r14 + r11 * 8]
    je .i_store
    jl .i_skip_a
    inc r11
    jmp .i_write
.i_skip_a:
    inc r10
    jmp .i_write
.i_store:
    mov [r8 + rcx * 8], rdx
    inc rcx
    inc r10
    inc r11
    jmp .i_write
.i_done:
    pop rax
    jmp .i_return
.i_fail:
    mov rax, -1
.i_return:
    pop r15
    pop r14
    pop r13
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
