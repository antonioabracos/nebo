; POSTFIXOS-MATRICIAIS-INVERSA-NORMAS-E-INNER-PRODUCTS-FECHAR-NUMERICAL-ORACLES-ERROR-BOUNDS-FORMATTER-E-CONSOLE-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F07 — stable machine/display metadata for linalg Result states.
bits 64
default rel

section .rodata
ok: db "ok"
shape: db "shape"
capacity: db "capacity"
overflow: db "overflow"
type: db "type"
singular: db "singular"
conditioning: db "conditioning"
unknown: db "unknown"

section .text
global linalg_status_name

; rdi=status -> rax=ASCII pointer,rdx=length. No I/O or allocation.
linalg_status_name:
    test rdi, rdi
    jz .ok
    cmp rdi, -1
    je .shape
    cmp rdi, -2
    je .capacity
    cmp rdi, -3
    je .overflow
    cmp rdi, -4
    je .type
    cmp rdi, -5
    je .singular
    cmp rdi, -6
    je .conditioning
    lea rax, [unknown]
    mov edx, 7
    ret
.ok:
    lea rax, [ok]
    mov edx, 2
    ret
.shape:
    lea rax, [shape]
    mov edx, 5
    ret
.capacity:
    lea rax, [capacity]
    mov edx, 8
    ret
.overflow:
    lea rax, [overflow]
    mov edx, 8
    ret
.type:
    lea rax, [type]
    mov edx, 4
    ret
.singular:
    lea rax, [singular]
    mov edx, 8
    ret
.conditioning:
    lea rax, [conditioning]
    mov edx, 12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
