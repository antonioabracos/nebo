; OPERADORES-DE-CONJUNTOS-E-RELACOES-FECHAR-MEMBERSHIP-E-NON-MEMBERSHIP-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F01 — membership over canonical sorted unique i64 sets.
bits 64
default rel

section .text
global set_contains_i64
global set_not_contains_i64

; rdi=elements, rsi=count, rdx=value -> rax=0|1
set_contains_i64:
    xor eax, eax
    xor r8d, r8d
    mov r9, rsi
.search:
    cmp r8, r9
    jae .done
    mov rcx, r8
    add rcx, r9
    shr rcx, 1
    mov r10, [rdi + rcx * 8]
    cmp r10, rdx
    je .found
    jl .right
    mov r9, rcx
    jmp .search
.right:
    lea r8, [rcx + 1]
    jmp .search
.found:
    mov eax, 1
.done:
    ret

set_not_contains_i64:
    call set_contains_i64
    xor eax, 1
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
