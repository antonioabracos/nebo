; OPERADORES-DE-CONJUNTOS-E-RELACOES-FECHAR-CARTESIAN-PRODUCT-E-CARDINALITY-BUDGETS-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F05 — bounded Cartesian product of canonical i64 sets.
bits 64
default rel

section .text
global set_cartesian_product_i64

; rdi=A,rsi=|A|,rdx=B,rcx=|B|,r8=out pairs,r9=pair capacity.
; Return pair count, or -1 on cardinality overflow/capacity failure without writes.
set_cartesian_product_i64:
    push r12
    mov r12, rdx
    mov rax, rsi
    mul rcx
    test rdx, rdx
    jnz .fail
    cmp rax, r9
    ja .fail
    push rax
    xor r10d, r10d
    xor edx, edx
.outer:
    cmp r10, rsi
    je .done
    xor r11d, r11d
.inner:
    cmp r11, rcx
    je .next_a
    mov rax, [rdi + r10 * 8]
    mov [r8 + rdx * 8], rax
    mov rax, [r12 + r11 * 8]
    mov [r8 + rdx * 8 + 8], rax
    add rdx, 2
    inc r11
    jmp .inner
.next_a:
    inc r10
    jmp .outer
.done:
    pop rax
    pop r12
    ret
.fail:
    mov rax, -1
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
