default rel
section .text
global nebo_differential_operator_plan
; edi=operator kind 0..4, esi=calculus domain gate; eax=typed status.
nebo_differential_operator_plan:
    test esi, esi
    jz .gate
    cmp edi, 4
    ja .kind
    xor eax, eax
    ret
.gate: mov eax, 1
    ret
.kind: mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
