; OPERADORES-DE-CONJUNTOS-E-RELACOES-FECHAR-SUBSET-SUPERSET-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F04 — subset/superset relations for canonical i64 sets.
bits 64
default rel

section .text
global set_is_subset_i64
global set_is_proper_subset_i64
global set_is_superset_i64
global set_is_proper_superset_i64

; rdi=A,rsi=|A|,rdx=B,rcx=|B| -> rax boolean (A subset-or-equal B).
set_is_subset_i64:
    cmp rsi, rcx
    ja .false
    xor r8d, r8d
    xor r9d, r9d
.scan:
    cmp r8, rsi
    je .true
    cmp r9, rcx
    je .false
    mov r10, [rdi + r8 * 8]
    cmp r10, [rdx + r9 * 8]
    je .matched
    jl .false
    inc r9
    jmp .scan
.matched:
    inc r8
    inc r9
    jmp .scan
.true:
    mov eax, 1
    ret
.false:
    xor eax, eax
    ret

set_is_proper_subset_i64:
    cmp rsi, rcx
    jae .proper_false
    jmp set_is_subset_i64
.proper_false:
    xor eax, eax
    ret

set_is_superset_i64:
    xchg rdi, rdx
    xchg rsi, rcx
    jmp set_is_subset_i64

set_is_proper_superset_i64:
    xchg rdi, rdx
    xchg rsi, rcx
    jmp set_is_proper_subset_i64

section .note.GNU-stack noalloc noexec nowrite progbits
